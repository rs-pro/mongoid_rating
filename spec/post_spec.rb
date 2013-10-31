require "spec_helper"

describe Post do

  before(:each) do
    @bob = User.create :name => "Bob"
    @alice = User.create :name => "Alice"
    @sally = User.create :name => "Sally"
    @post = Post.create :name => "Announcement"
    @article = Article.create :name => "Article"
  end

  subject { @post }
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
        @post.rate.should eql 5.0
      end

      context "when rate_value in rating range" do
        it { expect { @post.rate 1, @sally }.not_to raise_error }
      end

      context "when rate_value not in rating range" do
        it { expect { @post.rate 17, @sally }.to raise_error() }
        it { expect { @post.rate -17, @sally }.to raise_error() }
      end
    end

    describe "#rated?" do
      describe "for Bob" do
        specify { @post.rate_by?(@bob).should be_true }
      end
      describe "for Sally" do
        specify { @post.rate_by?(@sally).should be_false }
      end

      describe "when rated by someone else" do
        before do
          @post.rate 1, @alice
        end
        describe "for Bob" do
          specify { @post.rate_by?(@bob).should be_true }
        end
        describe "for Sally" do
          specify { @post.rate_by?(@sally).should be_false }
        end
        describe "for Alice" do
          specify { @post.rate_by?(@alice).should be_true }
        end
      end

      describe "when not rated by someone else" do
        describe "for Sally" do
          specify { @post.rate_by?(@sally).should be_false }
        end
      end
    end

    describe "#unrate" do
      before { @post.unrate @bob }

      it "should have null #rate_count" do
        @post.rate_count.should eql 0
      end

      it "should have null #rate" do
        @post.rate.should be_nil
      end
    end

    describe "#rate_count" do
      it "should know how many rates have been cast" do
        @post.rate 1, @sally
        @post.rate_count.should eql 2
      end
    end

    describe "#rate" do
      it "should calculate the average rate" do
        @post.rate 4, @sally
        @post.rate.should eq 2.5
      end
    end

    describe "#rate_by" do
      describe "should give mark" do
        specify { @post.rate_by(@bob).should eq 1}
      end
      describe "should give nil" do
        specify { @post.rate_by(@alice).should be_nil}
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
      @post.rate 3, @bob
      @post.save
      @f_post = Post.where(:name => "Announcement").first
    end

    describe "#rate_by?" do
      describe "for Bob" do
        specify { @f_post.rate_by?(@bob).should be_true }
      end

      describe "for Alice" do
        specify { @f_post.rate_by?(@alice).should be_false}
      end
    end

    describe "#rate" do
      specify { @f_post.rate.should eql 3.0 }
    end

    describe "#rate_count" do
      specify { @f_post.rate_count.should eql 1 }
    end
  end

  describe "#scopes" do
    before (:each) do
      @post.delete
      @post1 = Post.create(:name => "Post 1")
      @post2 = Post.create(:name => "Post 2")
      @post3 = Post.create(:name => "Post 3")
      @post4 = Post.create(:name => "Post 4")
      @post5 = Post.create(:name => "Post 5")
    end

    
    describe "#rate_by scope" do
      before :each do
        @post1.rate 5, @sally
        @post1.rate 3, @bob
        @post4.rate 1, @sally
      end

      it "should return proper count of posts rated by Bob" do
        Post.rate_by(@bob).size.should eql 1
      end

      it "should return proper count of posts rated by Sally" do
        Post.rate_by(@sally).size.should eql 2
      end
    end

    context 'rates' do
      before (:each) do
        @post1.rate 4, @alice
        @post2.rate 2, @alice
        @post3.rate 5, @alice
        @post4.rate 2, @alice
      end

      it '#highest_rate' do
        Post.highest_rate.count.should eq 4
        Post.highest_rate.first.id.should eq @post3.id
      end

      it "should return proper count of posts with rating 4..5" do
        Post.rate_in(4..5).size.should eql 2
      end

      it "should return proper count of posts with rating 0..2" do
        Post.rate_in(0..2).size.should eql 2
      end

      it "should return proper count of posts with rating 0..5" do
        Post.rate_in(0..5).size.should eql 4
      end

      describe "#highest_rate" do
        it "should return proper document" do
          Post.highest_rate.limit(1).first.name.should eql "Post 3"
        end
      end

      describe '#by_rate' do
        it "should return proper count of posts" do
          Post.by_rate.limit(10).count(true).should eq 5
        end

        it 'returns articles in proper order' do
          @post5.rate.should be_nil
          @post5[:rate_average].should be_nil

          Post.by_rate.to_a.should eq [@post3, @post1, @post2, @post4, @post5]
        end
      end
    end
  end
end

