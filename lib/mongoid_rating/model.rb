module Mongoid
  module Rating
    module Model
      extend ActiveSupport::Concern

      module ClassMethods
        # Make model rateable
        # 
        # @param [Hash] options a hash containings:
        # 
        # rateable :overall, range: -5..5
        #
        # Disable atomic eval (in case it's disabled on the database side)
        # rateable :design, range: -5..5, average: false
        # 
        # Disable average completely
        # rateable :quality, range: -5..5, average: true
        def rateable(field, options = {})
          options = {
            range: 1..5,
            rerate: true,
            eval: true,
            counters: true,
            float: true
          }.merge(options)
          field = field.to_sym
          sfield = field.inspect

          # total rates count
          field "#{field}_count", type: Integer, default: 0

          # rates data
          embeds_many "#{field}_data", as: :rateable, class_name: 'Mongoid::Rating::Rate', counter_cache: true

          # sum of all rates to calculate average
          field "#{field}_sum".to_sym, type: options[:float] ? Float : Integer

          # average rate value
          avg = "#{field}_average".to_sym
          field avg, type: Float
          savg = avg.inspect

          class_eval <<-RUBY, __FILE__, __LINE__+1
            scope :#{field}_by, ->(rater) {
              where("#{field}_data.rater_id" => rater.id, "#{field}_data.rater_type" => rater.class.to_s)
            }
            scope :#{field}_in, ->(range) {
              where(#{savg}.gte => range.begin, #{savg}.lte => range.end)
            }
            scope :highest_#{field}, -> {
              where(#{savg}.ne => nil).order_by([#{savg}, :desc])
            }

            def #{field}!(value, rater)
              value = value.to_i unless #{options[:float]}
              unless (#{options[:range]}).include?(value)
                raise "bad vote value"
              end
              raise "can't rate" unless can_#{field}?(rater)
              if #{options[:eval]}
                #{field}_data.where(rater_id: rater.id).destroy_all
                #{field}_data.create!(rater: rater, value: value)
                collection.database.session.cluster.with_primary do
                  doc = collection.database.command({
                    eval: 'function(id) { 
                      var oid = ObjectId(id);
                      var doc = db.' + collection.name + '.findOne( { _id : oid } );
                      if (doc) {
                        doc.#{field}_count = 0
                        doc.#{field}_sum = 0;
                        doc.#{field}_data.forEach(function(fd) {
                          doc.#{field}_sum += fd.value;
                          doc.#{field}_count += 1;
                        })
                        printjson(doc)
                        doc.#{field}_average = doc.#{field}_sum /doc.#{field}_count;
                        db.' + collection.name + '.save(doc);
                        return doc;
                      } else {
                        return false;
                      }
                    }',
                    args: [ id.to_s ]
                  })
                  self.#{field}_count = doc[:retval]["#{field}_count"]
                  self.#{field}_sum = doc[:retval]["#{field}_sum"]
                  self.#{field}_average = doc[:retval]["#{field}_average"]
                  remove_change(:#{field}_count)
                  remove_change(:#{field}_sum)
                  remove_change(:#{field}_average)

                end
              else
                un#{field}!(rater)
                atomically do
                  inc("#{field}_count" => 1, "#{field}_sum" => value)
                  #{field}_data.create!(rater: rater, value: value)
                  set("#{field}_average" => calc_#{field}_avg)
                end
              end
            end
            def calc_#{field}_avg
              if #{field}_count < 1
                nil
              else
                #{field}_sum.to_f / #{field}_count.to_f
              end
            end
            def un#{field}!(rater)
              r = #{field}_data.where(rater_id: rater.id).first
              if r.nil?
                # not rated before
              else
                atomically do
                  inc("#{field}_count" => -1, "#{field}_sum" => -r.value)
                  set("#{field}_average" => calc_#{field}_avg)
                  r.destroy
                end
              end
            end
            alias_method :un#{field}, :un#{field}!
            
            def did_#{field}?(rater)
              !raw_#{field}_by(rater).nil?
            end

            def can_#{field}?(rater)
              if #{options[:rerate]}
                true
              else
                !did_#{field}?(rater)
              end
            end

            def raw_#{field}_by(rater)
              #{field}_data.select do |rate|
                rate[:rater_id] == rater.id && rate[:rater_type] == rater.class.name
              end.first
            end

            def #{field}(value=nil, rater=nil)
              if rater.nil? && value.nil?
                #{field}_count.nil? ? nil : #{field}_average
              else
                #{field}!(value, rater)
              end
            end

            def #{field}_values
              #{field}_data.map(&:value)
            end

            def #{field}_by(rater)
              rate = raw_#{field}_by(rater)
              if rate.nil?
                nil
              else
                rate.value
              end
            end
            def #{field}_by?(rater)
              !#{field}_by(rater).nil?
            end
          RUBY
        end
      end
    end
  end
end

