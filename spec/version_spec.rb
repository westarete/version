require File.dirname(__FILE__) + '/spec_helper'

describe Version do
  before(:each) do
    Rails = stub('Rails') if ! defined?(Rails)
    Rails.stub!(:root => stub('root', :join => '/tmp/test_version_file'))
  end
  
  describe ".path" do
    it "should return a pathname object to the version file" do
      Version.path.to_s.should == "#{RAILS_ROOT}/VERSION"
    end
  end
  
  describe "when there is no version stored" do
    before(:each) do
      File.stub!(:exist? => false)
      @version = Version.new
    end
    describe "#number" do
      it "should return 0.0.0" do
        @version.number.should == '0.0.0'
      end
    end
    describe "#to_s" do
      it "should return v0.0.0" do
        @version.to_s.should == 'v0.0.0'
      end
    end
  end

  describe "when the stored version is nonsense" do
    before(:each) do
      set_up_test_version_file('nonsense')
    end
    describe ".new" do
      it "should raise an exception" do
        lambda {
          Version.new
        }.should raise_error(RuntimeError)
      end
    end
  end
  
  describe "when there is a whole lot of content in the version file" do
    before(:each) do
      set_up_test_version_file('1.2.3' + ('3'*100))
    end
    it "should raise an exception" do
      lambda {
        Version.new
      }.should raise_error(RuntimeError)
    end
    it "should not read the file" do
      File.should_not_receive(:open)
      begin
        Version.new
      rescue RuntimeError
      end
    end
  end
  
  describe "when there is trailing whitespace with the version" do
    before(:each) do
      set_up_test_version_file("1.2.3\n")
      @version = Version.new
    end
    it "should still be able to parse the version properly" do
      @version.to_s.should == 'v1.2.3'
    end
  end
  
  describe "when there is a valid version stored in the version file" do
    before(:each) do
      set_up_test_version_file('1.2.3')
      @version = Version.new
    end
    describe ".new" do
      it "should read from the version file" do
        File.should_receive(:open).with(Version.path)
        Version.new
      end
    end
    describe "#number" do
      it "should return the version number" do
        @version.number.should == '1.2.3'
      end
    end
    describe "#to_s" do
      it "should return the version number" do
        @version.to_s.should == 'v1.2.3'
      end
    end
    describe "#save" do
      before(:each) do
        # Substitute our own IO object to capture the output.
        @io = StringIO.new
        File.stub!(:open).and_yield(@io)
      end
      it "should write to the version file" do
        File.should_receive(:open).with(Version.path, 'w')
        @version.save
      end
      it "should write the version" do
        @version.save
        @io.string.should == 'v1.2.3'
      end
    end
    describe "#bump_major" do
      before(:each) do
        @version.stub!(:save)
      end
      it "should increment the major-level number and set the rest to zero" do
        @version.bump_major
        @version.to_s.should == 'v2.0.0'
      end
      it "should save the version back to the version file" do
        @version.should_receive(:save)
        @version.bump_major
      end
    end
    describe "#bump_minor" do
      before(:each) do
        @version.stub!(:save)
      end
      it "should increment the minor-level number and set the patch to zero" do
        @version.bump_minor
        @version.to_s.should == 'v1.3.0'
      end
      it "should save the version back to the version file" do
        @version.should_receive(:save)
        @version.bump_minor
      end
    end
    describe "#bump_patch" do
      before(:each) do
        @version.stub!(:save)
      end
      it "should increment the patch-level number" do
        @version.bump_patch
        @version.to_s.should == 'v1.2.4'
      end
      it "should save the version back to the version file" do
        @version.should_receive(:save)
        @version.bump_patch
      end
    end
  end
  
  # Set up a test version file that contains the given string.
  def set_up_test_version_file(string)
    File.stub!(:exist? => true)
    File.stub!(:size => string.length)
    io = stub('io', :read => string)
    File.stub!(:open).and_yield(io)
  end
  
end