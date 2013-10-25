require "spec_helper"

describe Article do

  before(:each) do
    @bob = User.create :name => "Bob"
    @sally = User.create :name => "Sally"
    @alice = User.create :name => "Alice"
  end

  context 'basic' do
    before(:each) do
      @article = Article.create :name => "Article"
      @article1 = Article.create :name => "Article 1"
      @article2 = Article.create :name => "Article 2"
    end

    subject { @article }
    it { should respond_to :overall }
    it { should respond_to :overall! }
    it { should respond_to :unoverall! }
    it { should respond_to :did_overall? }
    it { should respond_to :overall_average }
    it { should respond_to :overall_data }
    it { should respond_to :overall_by }

    describe "#overall_values" do
      it "should be an array with overall values" do
        @article.overall_values.should be_an_instance_of Array
        @article.overall! 1, @bob
        @article.overall_values.should eq [1]
      end
    end

    context "when overall" do
      before (:each) do
        @article.overall! 1, @bob
      end

      describe "#overall" do
        it "should track #overall properly" do
          @article.overall! 1, @sally
          @article.overall_count.should eql 2
          @article.overall.should eql 1.0
        end

        it "should not mark fields as dirty" do
          @article.overall_count_changed?.should be_false
          @article.overall_sum_changed?.should be_false
          @article.overall_average_changed?.should be_false
        end

        it "should limit #overalls by user properly" do
          @article.overall! 5, @bob
          @article.overall.should eql 5.0
        end

        context "when overall_value in rating range" do
          it { expect { @article.overall 1, @sally }.not_to raise_error }
        end

        context "when overall_value not in rating range" do
          it { expect { @article.overall 17, @sally }.to raise_error() }
          it { expect { @article.overall -17, @sally }.to raise_error() }
        end

        describe "when using positive values" do
          let(:num) { rand(1..5) }
          let(:exp) { ((num + 1) / 2.0) - 1 }
          it { expect { @article.overall num, @sally }.to change { @article.overall }.by(exp) }
        end

        describe "when using negative values" do
          let(:num) { -rand(1..5) }
          let(:exp) { ((num + 1) / 2.0) - 1 }
          it { expect { @article.overall num, @sally }.to change { @article.overall }.by(exp) }
        end
      end

      describe "#overall_by?" do
        describe "for Bob" do
          specify { @article.overall_by?(@bob).should be_true }
        end
        describe "for Bob" do
          specify { @article1.overall_by?(@bob).should be_false }
          specify { @article.overall_by?(@alice).should be_false }
        end

        describe "when overall by someone else" do
          before do
            @article.overall 1, @alice
          end

          describe "for Alice" do
            specify { @article.overall_by?(@alice).should be_true }
          end
        end

        describe "when not overall by someone else" do
          describe "for Sally" do
            specify { @article.overall_by?(@sally).should be_false }
          end
        end
      end

      describe "#unoverall" do
        before { @article.unoverall @bob }

        it "should have null #overall_count" do
          @article.overall_count.should eql 0
        end

        it "should have null #overall" do
          @article.overall.should be_nil
        end

        it "#overall_by?(@bob) should be false after unoverall" do
          @article.overall_by?(@bob).should be_false
        end
      end

      describe "#overall_count" do
        it "should know how many overalls have been cast" do
          @article.overall 1, @sally
          @article.overall_count.should eql 2
        end
      end

      describe "#rating" do
        it "should calculate the average overall" do
          @article.overall 4, @sally
          @article.overall.should eq 2.5
        end

        it "should calculate the average overall if the result is zero" do
          @article.overall -1, @sally
          @article.overall.should eq 0.0
        end
      end
    end

    context "when not overall" do
      describe "#overalls" do
        specify { @article.overall_count.should eql 0 }
      end

      describe "#rating" do
        specify { @article.overall.should be_nil }
      end

      describe "#unoverall" do
        before do
          @article.unoverall @sally
        end

        it "should have null #overall_count" do
          @article.overall_count.should eql 0
        end

        it "should have null #overalls" do
          @article.overall.should be_nil
        end
      end
    end

    context "when saving the collection" do
      before (:each) do
        @article.overall 3, @bob
        @article.overall -5, @sally
        @article.save
        @f_article = Article.where(:name => "Article").first
      end

      it "disallows incorrect rates" do
        expect { @article.overall 8, @bob }.to raise_error
        expect { @article.overall -10, @sally }.to raise_error
      end

      describe "#overall_by?" do
        describe "for Bob" do
          specify { @f_article.overall_by?(@bob).should be_true }
          specify { @f_article.overall_by(@bob).should eq 3 }
        end

        describe "for Sally" do
          specify { @f_article.overall_by?(@sally).should be_true }
          specify { @f_article.overall_by(@sally).should eq -5 }
        end

        describe "for Alice" do
          specify { @f_article.overall_by?(@alice).should be_false}
          specify { @f_article.overall_by(@alice).should be_nil }
        end
      end

      describe "#overall" do
        specify { @f_article.overall.should eql -1.0 }
      end

      describe "#overall_count" do
        specify { @f_article.overall_count.should eql 2 }
      end
    end
  end

  describe "#scopes" do
    before :each do
      @article1 = Article.create(:name => "Article 1")
      @article2 = Article.create(:name => "Article 2")
      @article3 = Article.create(:name => "Article 3")
      @article4 = Article.create(:name => "Article 4")
      @article5 = Article.create(:name => "Article 5")
    end

    describe "#overall_by" do
      before :each do
        @article1.overall 5, @sally
        @article1.overall 3, @bob
        @article4.overall 1, @sally
      end
      it "should return proper count of articles overall by Bob" do
        Article.overall_by(@bob).size.should eql 1
      end

      it "should return proper count of articles overall by Sally" do
        Article.overall_by(@sally).size.should eql 2
      end
    end

    context 'rates' do
      before (:each) do
        @article1.overall 4, @alice
        @article2.overall 2, @alice
        @article3.overall 5, @alice
        @article4.overall 1, @alice
      end
      describe "#overall_in" do
        it "should return proper count of articles with rating 4..5" do
          Article.overall_in(4..5).to_a.length.should eql 2
        end

        it "should return proper count of articles with rating 0..2" do
          Article.overall_in(0..2).to_a.length.should eql 2
        end

        it "should return proper count of articles with rating 0..5" do
          Article.overall_in(0..5).to_a.length.should eql 4
        end
      end

      describe "#highest_overall" do
        it "should return proper count of articles" do
          Article.highest_overall.limit(1).count(true).should eq 1
        end

        it "should return proper count of articles" do
          Article.highest_overall.limit(10).count(true).should eq 4
        end

        it "should return proper document" do
          Article.highest_overall.limit(1).first.name.should eql "Article 3"
        end
        it 'returns articles in proper order' do
          Article.highest_overall.to_a.should eq [@article3, @article1, @article2, @article4]
        end
      end

      describe '#by_overall' do
        it "should return proper count of articles" do
          Article.by_overall.limit(10).count(true).should eq 5
          Article.by_overall.to_a.should eq [@article3, @article1, @article2, @article4, @article5]
        end

        it 'returns articles in proper order' do

        end
      end
    end

  end
end
