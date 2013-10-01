require "spec_helper"

describe Post do

  before(:each) do
    @bob = User.create :name => "Bob"
    @alice = User.create :name => "Alice"
    @sally = User.create :name => "Sally"
    @post = Post.create :name => "Announcement"
    @post = Article.create :name => "Article"
  end

  subject { @comment1 }
  it { should respond_to :rate }
  it { should respond_to :rate! }
  it { should respond_to :unrate! }
  it { should respond_to :did_rate? }
  it { should respond_to :rate_average }
  it { should respond_to :rate_data }
  it { should respond_to :rate_by }


  describe "#rate_values" do
    it "should be an array with rated values" do
      @post.rate_values.should be_an_instance_of Array
      @post.rate! 1, @bob
      @post.rate_values.should eq [1]
    end
  end

  context "when rated" do
    before (:each) do
      @post.rate! 1, @bob
    end

    describe "#rate" do
      it "should track #rates properly" do
        @post.rate! 1, @sally
        @post.rate_count.should eql 2
      end

      it "should limit #rates by user properly" do
        @post.rate! 5, @bob
        @post.rate.should eql 5
      end

      context "when rate_value in rating range" do
        it { expect { @post.rate 1, @sally }.not_to raise_error }
      end

      context "when rate_value not in rating range" do
        it { expect { @post.rate 17, @sally }.to raise_error() }
        it { expect { @post.rate -17, @sally }.to raise_error() }
      end

      describe "when using negative values" do
        let(:num) { -rand(1..100) }

        it { expect { @post.rate num, @sally }.to change { @post.overall }.by(num) }
        it { expect { @post.rate -1, @sally, -num }.to change { @post.overall }.by(num) }
      end
    end

    describe "#rated?" do
      describe "for Bob" do
        specify { @post.rate_by?(@bob).should be_true }
      end
      describe "for Bob" do
        specify { @post.rate_by?(@bob).should be_false }
      end

      describe "when rated by someone else" do
        before do
          @post.rate 1, @alice
        end

        describe "for Alice" do
          specify { @post.rated_by?(@alice).should be_true }
        end
      end

      describe "when not rated by someone else" do
        describe "for Sally" do
          specify { @post.rated_by?(@sally).should be_false }
        end
      end
    end

    describe "#unrate" do
      before { @post.unrate @bob }

      it "should have null #rate_count" do
        @post.rate_count.should eql 0
      end

      it "should have null #rates" do
        @post.rates.should eql 0
      end

      it "should be unrated" do
        @post.rated?.should be_false
      end
    end

    describe "#rate_count" do
      it "should know how many rates have been cast" do
        @post.rate 1, @sally
        @post.rate_count.should eql 2
      end
    end

    describe "#rating" do
      it "should calculate the average rate" do
        @post.rate 4, @sally
        @post.rating.should eq 2.5
      end

      it "should calculate the average rate if the result is zero" do
        @post.rate -1, @sally
        @post.rating.should eq 0.0
      end
    end

    describe "#previous_rating" do
      it "should store previous value of the average rate" do
        @post.rate 4, @sally
        @post.previous_rating.should eq 1.0
      end

      it "should store previous value of the average rate after two changes" do
        @post.rate -1, @sally
        @post.rate 4, @sally
        @post.previous_rating.should eq 0.0
      end
    end

    describe "#rating_delta" do
      it "should calculate delta of previous and new ratings" do
        @post.rate 4, @sally
        @post.rating_delta.should eq 1.5
      end

      it "should calculate delta of previous and new ratings" do
        @post.rate -1, @sally
        @post.rating_delta.should eq -1.0
      end
    end

    describe "#unweighted_rating" do
      it "should calculate the unweighted average rate" do
        @post.rate 4, @sally
        @post.unweighted_rating.should eq 2.5
      end

      it "should calculate the unweighted average rate if the result is zero" do
        @post.rate -1, @sally
        @post.unweighted_rating.should eq 0.0
      end
    end

    describe "#user_mark" do
      describe "should give mark" do
        specify { @post.user_mark(@bob).should eq 1}
      end
      describe "should give nil" do
        specify { @post.user_mark(@alice).should be_nil}
      end
    end
  end

  context "when not rated" do
    describe "#rates" do
      specify { @post.rate_count.should eql 0 }
    end

    describe "#rating" do
      specify { @post.rate.should be_nil }
    end

    describe "#unrate" do
      before do
        @post.unrate @sally
      end

      it "should have null #rate_count" do
        @post.rate_count.should eql 0
      end

      it "should have null #rates" do
        @post.rate.should be_nil
      end
    end
  end

  context "when saving the collection" do
    before (:each) do
      @post.rate 8, @bob
      @post.rate -10, @sally
      @post.save
      @f_post = Post.where(:name => "Announcement").first
    end

    describe "#rated_by?" do
      describe "for Bob" do
        specify { @f_post.rate_by?(@bob).should be_true }
      end

      describe "for Sally" do
        specify { @f_post.rate_by?(@sally).should be_true }
      end

      describe "for Alice" do
        specify { @f_post.rate_by?(@alice).should be_false}
      end
    end

    describe "#rate" do
      specify { @f_post.rate.should eql -2 }
    end

    describe "#rate_count" do
      specify { @f_post.rate_count.should eql 2 }
    end

  describe "#scopes" do
    before (:each) do
      @post.delete
      @post1 = Post.create(:name => "Post 1")
      @post2 = Post.create(:name => "Post 2")
      @post3 = Post.create(:name => "Post 3")
      @post4 = Post.create(:name => "Post 4")
      @post5 = Post.create(:name => "Post 5")
      @post1.rate_and_save 5, @sally
      @post1.rate_and_save 3, @bob
      @post4.rate_and_save 1, @sally
    end

    describe "#unrated" do
      it "should return proper count of unrated posts" do
        Post.unrated.size.should eql 3
      end
    end

    describe "#rated" do
      it "should return proper count of rated posts" do
        Post.rated.size.should eql 2
      end
    end

    describe "#rated_by" do
      it "should return proper count of posts rated by Bob" do
        Post.rated_by(@bob).size.should eql 1
      end

      it "should return proper count of posts rated by Sally" do
        Post.rated_by(@sally).size.should eql 2
      end
    end

    describe "#with_rating" do
      before (:each) do
        @post1.rate_and_save 4, @alice
        @post2.rate_and_save 2, @alice
        @post3.rate_and_save 5, @alice
        @post4.rate_and_save 2, @alice
      end

      it "should return proper count of posts with rating 4..5" do
        Post.with_rating(4..5).size.should eql 2
      end

      it "should return proper count of posts with rating 0..2" do
        Post.with_rating(0..2).size.should eql 2
      end

      it "should return proper count of posts with rating 0..5" do
        Post.with_rating(0..5).size.should eql 4
      end
    end

    describe "#highest_rated" do
      it "should return proper count of posts" do
        #mongoid has problems with returning count of documents (https://github.com/mongoid/mongoid/issues/817)
        posts_count = 0
        Post.highest_rated(1).each {|x| posts_count+=1 }
        posts_count.should eql 1
      end

      it "should return proper count of posts" do
        #mongoid has problems with returning count of documents (https://github.com/mongoid/mongoid/issues/817)
        posts_count = 0
        Post.highest_rated(10).each {|x| posts_count+=1 }
        posts_count.should eql 5
      end

      it "should return proper document" do
        Post.highest_rated(1).first.name.should eql "Post 1"
      end
    end
  end
end

