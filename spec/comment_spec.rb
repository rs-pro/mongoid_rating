require "spec_helper"

# specs for embedded model with rating
describe Comment do

  before(:each) do
    @bob = User.create :name => "Bob"
    @alice = User.create :name => "Alice"
    @sally = User.create :name => "Sally"
    @post = Post.create :name => "Announcement"
    @comment1 = @post.comments.create :content => 'Hello!'
    @comment2 = @post.comments.create :content => 'Goodbye!'
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
    it "should contain an array of rating marks" do
      @comment1.rate_values.should be_an_instance_of Array
      @comment1.rate_values.should eq []

      @comment1.rate! 2, @bob
      @comment1.rate_values.should eq [2]
    end
    
    it 'allows string rate' do
      @comment1.rate! '3', @bob
      @comment1.rate_values.should eq [3]
    end

    it 'disallows float' do
      @comment1.rate! 2.5, @bob
      @comment1.rate_values.should eq [2]
      @comment1.rate! '2.7', @bob
      @comment1.rate_values.should eq [2]
    end

    it 'fmt_rate' do
      @comment1.fmt_rate.should eq '0'
      @comment1.rate! '2.0', @bob
      @comment1.fmt_rate.should eq '2'
    end
  end

  context "when rated" do
    before (:each) do
      @comment1.rate! 2, @bob
    end

    describe "#rate" do
      it "should track #rates properly" do
        @comment1.rate! 3, @sally
        @comment1.rate.should eq 2.5
      end

      it "should limit #rates by user properly" do
        @comment1.rate! 5, @bob
        @comment1.rate.should eql 5.0
      end

      context "when rate_value in rating range" do
        it { expect { @comment1.rate 1, @sally }.not_to raise_error }
      end
      
      context "when rate_value not in rating range" do
        it { expect { @comment1.rate 9, @sally }.to raise_error() }
      end

      describe "when using positive values" do
        let(:num) { rand(1..5) }
        let(:exp) { ((num + 2) / 2.0) - 2 }
        it { expect { @comment1.rate num, @sally }.to change { @comment1.rate }.by(exp) }
      end
    end

    describe "#rate_by" do
      describe "for Bob" do
        specify { @comment1.rate_by?(@bob).should be_true }
        specify { @comment1.rate_by(@bob).should eq 2 }
      end
      describe "for Bob" do
        specify { @comment2.rate_by(@bob).should be_nil }
      end

      describe "when rated by someone else" do
        before do
          @comment1.rate 1, @alice
        end

        describe "for Alice" do
          specify { @comment1.rate_by?(@alice).should be_true }
        end
      end

      describe "when not rated by someone else" do
        describe "for Sally" do
          specify { @comment1.rate_by(@sally).should be_false }
        end
      end
    end

    describe "#unrate" do
      before { @comment1.unrate! @bob }

      it "should have null #rate_count" do
        @comment1.rate_count.should eql 0
      end

      it "should have null #rate" do
        @comment1.rate.should be_nil
      end

      it "should be not rated by bob" do
        @comment1.rate_by(@bob).should be_nil
      end

      it "should have no rate_data" do
        @comment1.rate_data.should eq []
      end
    end

    describe "#rate_count" do
      it "should know how many rates have been cast" do
        @comment1.rate! 1, @sally
        @comment1.rate_count.should eql 2
      end
    end

    describe "#rating" do
      it "should calculate the average rate" do
        @comment1.rate! 4, @sally
        @comment1.rate.should eq 3.0
      end
    end
  end

  context "when not rated" do
    describe "#rate" do
      specify { @comment1.rate.should be_nil }
    end

    describe "#unrate" do
      before do
        @comment1.unrate! @sally
      end

      it "should have zero #rate_count" do
        @comment1.rate_count.should eql 0
      end

      it "should have null #rate" do
        @comment1.rate.should be_nil
      end
    end
  end

  context "when saving the collection" do
    before (:each) do
      @comment1.rate 3, @bob
      @comment1.rate 2, @sally
      @comment1.save
      @comment1.reload
      @f_post = Post.where(:name => "Announcement").first
      @f_comment = @f_post.comments.where(:content => "Hello!").first
    end

    describe "#rated_by?" do
      describe "for Bob" do
        specify { @f_comment.rate_by?(@bob).should be_true}
      end

      describe "for Sally" do
        specify { @f_comment.rate_by?(@sally).should be_true }
      end

      describe "for Alice" do
        specify { @f_comment.rate_by?(@alice).should be_false}
      end
    end

    describe "#rate" do
      specify { @f_comment.rate.should eql 2.5 }
    end

    describe "#rate_count" do
      specify { @f_comment.rate_count.should eql 2 }
    end
  end

  describe "#scopes" do
    before (:each) do
      @post1 = Post.create(:name => "Post 1")
      @c1 = @post1.comments.create(:content => 'c1')
      @c2 = @post1.comments.create(:content => 'c2')
      @c3 = @post1.comments.create(:content => 'c3')
      @c4 = @post1.comments.create(:content => 'c4')
      @c5 = @post1.comments.create(:content => 'c5')
      @c1.rate! 5, @sally
      @c1.rate! 3, @bob
      @c4.rate! 1, @sally
    end

    describe "#rate_by" do
      it "should return proper count of comments rated by Bob" do
        @post1.comments.rate_by(@bob).size.should eql 1
      end

      it "should return proper count of comments rated by Sally" do
        @post1.comments.rate_by(@sally).size.should eql 2
      end
    end


    describe "#highest_rate" do
      # count is broken on embedded models
      it "should return proper count of comments" do
        @post1.comments.highest_rate.limit(1).to_a.length.should eq 1
      end

      it "should return proper count of comments" do
        # includes only with rating
        @post1.comments.highest_rate.limit(10).to_a.length.should eq 2
      end

      it "should return proper document" do
        @post1.comments.highest_rate.limit(1).first.content.should eql "c1"
      end
    end
  end
end
