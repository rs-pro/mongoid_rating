require "spec_helper"

describe Article do

  before(:each) do
    @bob = User.create :name => "Bob"
    @sally = User.create :name => "Sally"
    @alice = User.create :name => "Alice"
    @article = Article.create :name => "Article"
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
        @article.overall.should eql 5
      end

      context "when overall_value in rating range" do
        it { expect { @article.overall 1, @sally }.not_to raise_error }
      end

      context "when overall_value not in rating range" do
        it { expect { @article.overall 17, @sally }.to raise_error() }
        it { expect { @article.overall -17, @sally }.to raise_error() }
      end

      describe "when using negative values" do
        let(:num) { -rand(1..100) }

        it { expect { @article.overall num, @sally }.to change { @post.overall }.by(num) }
        it { expect { @article.overall -1, @sally, -num }.to change { @post.overall }.by(num) }
      end
    end

    describe "#overall?" do
      describe "for Bob" do
        specify { @article.overall_by?(@bob).should be_true }
      end
      describe "for Bob" do
        specify { @article.overall_by?(@bob).should be_false }
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

      it "should have null #overalls" do
        @article.overalls.should eql 0
      end

      it "should be unoverall" do
        @article.overall?.should be_false
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
        @article.rating.should eq 2.5
      end

      it "should calculate the average overall if the result is zero" do
        @article.overall -1, @sally
        @article.rating.should eq 0.0
      end
    end

    describe "#previous_rating" do
      it "should store previous value of the average overall" do
        @article.overall 4, @sally
        @article.previous_rating.should eq 1.0
      end

      it "should store previous value of the average overall after two changes" do
        @article.overall -1, @sally
        @article.overall 4, @sally
        @article.previous_rating.should eq 0.0
      end
    end

    describe "#rating_delta" do
      it "should calculate delta of previous and new ratings" do
        @article.overall 4, @sally
        @article.rating_delta.should eq 1.5
      end

      it "should calculate delta of previous and new ratings" do
        @article.overall -1, @sally
        @article.rating_delta.should eq -1.0
      end
    end

    describe "#unweighted_rating" do
      it "should calculate the unweighted average overall" do
        @article.overall 4, @sally
        @article.unweighted_rating.should eq 2.5
      end

      it "should calculate the unweighted average overall if the result is zero" do
        @article.overall -1, @sally
        @article.unweighted_rating.should eq 0.0
      end
    end

    describe "#user_mark" do
      describe "should give mark" do
        specify { @article.user_mark(@bob).should eq 1}
      end
      describe "should give nil" do
        specify { @article.user_mark(@alice).should be_nil}
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
      @article.overall 8, @bob
      @article.overall -10, @sally
      @article.save
      @f_article = Article.where(:name => "Announcement").first
    end

    describe "#overall_by?" do
      describe "for Bob" do
        specify { @f_article.overall_by?(@bob).should be_true }
      end

      describe "for Sally" do
        specify { @f_article.overall_by?(@sally).should be_true }
      end

      describe "for Alice" do
        specify { @f_article.overall_by?(@alice).should be_false}
      end
    end

    describe "#overall" do
      specify { @f_article.overall.should eql -2 }
    end

    describe "#overall_count" do
      specify { @f_article.overall_count.should eql 2 }
    end
  end

  describe "#scopes" do
    before (:each) do
      @article.delete
      @article1 = Article.create(:name => "Post 1")
      @article2 = Article.create(:name => "Post 2")
      @article3 = Article.create(:name => "Post 3")
      @article4 = Article.create(:name => "Post 4")
      @article5 = Article.create(:name => "Post 5")
      @article1.overall_and_save 5, @sally
      @article1.overall_and_save 3, @bob
      @article4.overall_and_save 1, @sally
    end

    describe "#unoverall" do
      it "should return proper count of unoverall articles" do
        article.unoverall.size.should eql 3
      end
    end

    describe "#overall" do
      it "should return proper count of overall articles" do
        article.overall.size.should eql 2
      end
    end

    describe "#overall_by" do
      it "should return proper count of articles overall by Bob" do
        article.overall_by(@bob).size.should eql 1
      end

      it "should return proper count of articles overall by Sally" do
        article.overall_by(@sally).size.should eql 2
      end
    end

    describe "#with_rating" do
      before (:each) do
        @article1.overall 4, @alice
        @article2.overall 2, @alice
        @article3.overall 5, @alice
        @article4.overall 2, @alice
      end

      it "should return proper count of articles with rating 4..5" do
        article.overall_in(4..5).to_a.length.should eql 2
      end

      it "should return proper count of articles with rating 0..2" do
        article.overall_in(0..2).to_a.length.should eql 2
      end

      it "should return proper count of articles with rating 0..5" do
        article.overall_in(0..5).to_a.length.should eql 4
      end
    end

    describe "#highest_overall" do
      it "should return proper count of articles" do
        article.highest_overall.limit(1).count(true).should eq 1
      end

      it "should return proper count of articles" do
        article.highest_overall.limit(10).count(true).should eq 4
      end

      it "should return proper document" do
        article.highest_overall.limit(1).first.name.should eql "Article 1"
      end
    end
  end
end
