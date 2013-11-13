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
        # Disable average completely
        # rateable :design, range: -5..5, average: false
        # rateable :quality, range: -5..5, average: true
        #
        # float: whether to allow non-integer rates (default true)
        #
        def rateable(field, opt = {})
          options = {
            range: 1..5,
            rerate: true,
            counters: true,
            float: true,
          }.merge(opt)
          options[:no_rate] ||= options[:float] ? '0.0' : '0'
          options[:format]  ||= options[:float] ? '%.1f' : '%d'

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

            scope :by_#{field}, -> {
              order_by([#{savg}, :desc])
            }
            scope :highest_#{field}, -> {
              where(#{savg}.ne => nil).order_by([#{savg}, :desc])
            }

            # return user's rate if rated otherwise formatted rate value
            # good for Raty JS plugin
            def fmt_#{field}(user = nil)
              if !user.nil? && #{field}_by?(user)
                #{options[:format].inspect} % #{field}_by(user)
              elsif #{field}.nil?
                #{options[:no_rate].class.name == 'String' ? options[:no_rate].inspect : options[:no_rate]}
              else
                #{options[:format].inspect} % #{field}
              end
            end

            def #{field}!(value, rater)
              if #{options[:float]}
               value = value.to_f
              else
               value = value.to_i 
              end
              unless (#{options[:range]}).include?(value)
                raise "bad vote value"
              end
              raise "can't rate" unless can_#{field}?(rater)
              un#{field}!(rater)
              atomically do
                inc("#{field}_count" => 1, "#{field}_sum" => value)
                #{field}_data.create!(rater: rater, value: value)
                set("#{field}_average" => calc_#{field}_avg)
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

