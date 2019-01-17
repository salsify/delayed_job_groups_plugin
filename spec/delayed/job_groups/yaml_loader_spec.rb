describe Delayed::JobGroups::YamlLoader do
  class Foo; end

  describe "#load" do
    context "with a correct yaml object representation" do
      let(:yaml) { '--- !ruby/object:Foo {}' }

      it "deserializes properly" do
        expect(Delayed::JobGroups::YamlLoader.load(yaml)).to be_a(Foo)
      end
    end

    context "with an incorrect yaml object representation" do
      let(:yaml) { 'foo' }

      it "deserializes properly" do
        expect(Delayed::JobGroups::YamlLoader.load(yaml)).to eq('foo')
      end
    end
  end

  describe "#dump" do
    context "with an object" do
      let(:object) { Foo.new }

      it "deserializes properly" do
        expect(Delayed::JobGroups::YamlLoader.dump(object)).to eq("--- !ruby/object:Foo {}\n")
      end
    end

    context "with a nil object" do
      let(:object) { nil }

      it "deserializes properly" do
        expect(Delayed::JobGroups::YamlLoader.dump(object)).to eq(nil)
      end
    end
  end
end
