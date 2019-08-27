# frozen_string_literal: true

RSpec.describe ZohoCRM::Utils::Copiable do
  describe ".deep_clone" do
    describe "String" do
      context "when frozen" do
        it "is cloned" do
          original = "a"
          cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

          expect(original.object_id).to_not eq(cloned.object_id)
        end
      end

      context "when mutable" do
        it "is cloned" do
          original = +"a"
          cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

          expect(original.object_id).to_not eq(cloned.object_id)
        end
      end
    end

    context "Symbol" do
      it "is not cloned" do
        original = :foo
        cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

        expect(original.object_id).to eq(cloned.object_id)
      end
    end

    context "NilClass" do
      it "is not cloned" do
        original = nil
        cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

        expect(original.object_id).to eq(cloned.object_id)
      end
    end

    context "TrueClass" do
      it "is not cloned" do
        original = true
        cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

        expect(original.object_id).to eq(cloned.object_id)
      end
    end

    context "FalseClass" do
      it "is not cloned" do
        original = false
        cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

        expect(original.object_id).to eq(cloned.object_id)
      end
    end

    context "Integer" do
      it "is not cloned" do
        original = 1
        cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

        expect(original.object_id).to eq(cloned.object_id)
      end
    end

    context "Float" do
      it "is not cloned" do
        original = 1.0
        cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

        expect(original.object_id).to eq(cloned.object_id)
      end
    end

    context "Object" do
      it "is cloned" do
        klass = Class.new
        original = klass.new
        cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

        expect(original.object_id).to_not eq(cloned.object_id)
      end
    end

    context "Class" do
      it "is cloned" do
        original = Class.new
        cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

        expect(original.object_id).to_not eq(cloned.object_id)
      end
    end

    context "Method" do
      it "is cloned" do
        original = Kernel.method(:puts)
        cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

        expect(original.object_id).to_not eq(cloned.object_id)
      end
    end

    context "Array" do
      it "is cloned" do
        original = []
        cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

        expect(original.object_id).to_not eq(cloned.object_id)
      end

      context "when containing frozen strings" do
        it "they are cloned" do
          original = ["a"]
          cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

          original_ids = original.map(&:object_id)
          cloned_ids = cloned.map(&:object_id)

          expect(original_ids).to_not match_array(cloned_ids)
        end
      end

      context "when containing mutable strings" do
        it "they are cloned" do
          original = [+"a"]
          cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

          original_ids = original.map(&:object_id)
          cloned_ids = cloned.map(&:object_id)

          expect(original_ids).to_not match_array(cloned_ids)
        end
      end
    end

    context "Hash" do
      it "is cloned" do
        original = {}
        cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

        expect(original.object_id).to_not eq(cloned.object_id)
      end

      context "when keys and values are immutable" do
        it "keys are not cloned" do
          original = {a: 1}
          cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

          original_ids = original.each_key.map(&:object_id)
          cloned_ids = cloned.each_key.map(&:object_id)

          expect(original_ids).to match_array(cloned_ids)
        end

        it "values are not cloned" do
          original = {a: 1, b: true}
          cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

          original_ids = original.each_value.map(&:object_id)
          cloned_ids = cloned.each_value.map(&:object_id)

          expect(original_ids).to match_array(cloned_ids)
        end
      end

      context "when keys and values are mutable" do
        it "keys are cloned" do
          original = {Object.new => 1, "b" => 2}
          cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

          original_ids = original.each_key.map(&:object_id)
          cloned_ids = cloned.each_key.map(&:object_id)

          expect(original_ids).to_not match_array(cloned_ids)
        end

        it "values are cloned" do
          original = {a: Object.new, b: "b"}
          cloned = ZohoCRM::Utils::Copiable.deep_clone(original)

          original_ids = original.each_value.map(&:object_id)
          cloned_ids = cloned.each_value.map(&:object_id)

          expect(original_ids).to_not match_array(cloned_ids)
        end
      end
    end
  end

  describe ".deep_dup" do
    describe "String" do
      context "when frozen" do
        it "is dupped" do
          original = "a"
          dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

          expect(original.object_id).to_not eq(dupped.object_id)
        end
      end

      context "when mutable" do
        it "is dupped" do
          original = +"a"
          dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

          expect(original.object_id).to_not eq(dupped.object_id)
        end
      end
    end

    context "Symbol" do
      it "is not dupped" do
        original = :foo
        dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

        expect(original.object_id).to eq(dupped.object_id)
      end
    end

    context "NilClass" do
      it "is not dupped" do
        original = nil
        dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

        expect(original.object_id).to eq(dupped.object_id)
      end
    end

    context "TrueClass" do
      it "is not dupped" do
        original = true
        dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

        expect(original.object_id).to eq(dupped.object_id)
      end
    end

    context "FalseClass" do
      it "is not dupped" do
        original = false
        dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

        expect(original.object_id).to eq(dupped.object_id)
      end
    end

    context "Integer" do
      it "is not dupped" do
        original = 1
        dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

        expect(original.object_id).to eq(dupped.object_id)
      end
    end

    context "Float" do
      it "is not dupped" do
        original = 1.0
        dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

        expect(original.object_id).to eq(dupped.object_id)
      end
    end

    context "Object" do
      it "is dupped" do
        klass = Class.new
        original = klass.new
        dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

        expect(original.object_id).to_not eq(dupped.object_id)
      end
    end

    context "Class" do
      it "is dupped" do
        original = Class.new
        dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

        expect(original.object_id).to_not eq(dupped.object_id)
      end
    end

    context "Method" do
      it "is not dupped" do
        original = Kernel.method(:puts)
        dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

        expect(original.object_id).to eq(dupped.object_id)
      end
    end

    context "Array" do
      it "is dupped" do
        original = []
        dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

        expect(original.object_id).to_not eq(dupped.object_id)
      end

      context "when containing frozen strings" do
        specify "they are dupped", aggregate_failures: true do
          original = ["a"]
          dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

          original_ids = original.map(&:object_id)
          dupped_ids = dupped.map(&:object_id)

          original.each do |value|
            expect(value).to be_frozen
          end

          dupped.each do |value|
            expect(value).to_not be_frozen
          end

          expect(original_ids).to_not match_array(dupped_ids)
        end
      end

      context "when containing mutable strings" do
        specify "they are dupped" do
          original = [+"a"]
          dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

          original_ids = original.map(&:object_id)
          dupped_ids = dupped.map(&:object_id)

          expect(original_ids).to_not match_array(dupped_ids)
        end
      end
    end

    context "Hash" do
      it "is dupped" do
        original = {}
        dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

        expect(original.object_id).to_not eq(dupped.object_id)
      end

      specify "keys are copied" do
        original = {a: 1, b: 2}
        dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

        original_ids = original.each_key.map(&:object_id)
        dupped_ids = dupped.each_key.map(&:object_id)

        expect(original_ids).to match_array(dupped_ids)
      end

      context "when values are frozen strings" do
        specify "values are dupped", aggregate_failures: true do
          original = {a: "foo", b: "bar"}
          dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

          original_ids = original.each_value.map(&:object_id)
          dupped_ids = dupped.each_value.map(&:object_id)

          original.each_value do |value|
            expect(value).to be_frozen
          end

          dupped.each_value do |value|
            expect(value).to_not be_frozen
          end

          expect(dupped_ids).to_not match_array(original_ids)
        end
      end

      context "when values are frozen" do
        specify "values are not dupped" do
          original = {a: 1, b: 2}
          dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

          original_ids = original.each_value.map(&:object_id)
          dupped_ids = dupped.each_value.map(&:object_id)

          expect(original_ids).to match_array(dupped_ids)
        end
      end

      context "when values are mutable" do
        specify "values are dupped" do
          original = {a: Object.new, b: +"b"}
          dupped = ZohoCRM::Utils::Copiable.deep_dup(original)

          original_ids = original.each_value.map(&:object_id)
          dupped_ids = dupped.each_value.map(&:object_id)

          expect(original_ids).to_not match_array(dupped_ids)
        end
      end
    end
  end

  describe ".clonable?" do
    it { expect(ZohoCRM::Utils::Copiable.clonable?(:foo)).to be(false) }
    it { expect(ZohoCRM::Utils::Copiable.clonable?(nil)).to be(false) }
    it { expect(ZohoCRM::Utils::Copiable.clonable?(true)).to be(false) }
    it { expect(ZohoCRM::Utils::Copiable.clonable?(false)).to be(false) }
    it { expect(ZohoCRM::Utils::Copiable.clonable?(1)).to be(false) }
    it { expect(ZohoCRM::Utils::Copiable.clonable?(1.0)).to be(false) }
    it { expect(ZohoCRM::Utils::Copiable.clonable?(Kernel.method(:puts))).to be(true) }

    describe "a frozen String" do
      it { expect(ZohoCRM::Utils::Copiable.clonable?("a")).to be(true) }
    end

    describe "a mutable String" do
      it { expect(ZohoCRM::Utils::Copiable.clonable?(+"a")).to be(true) }
    end

    it { expect(ZohoCRM::Utils::Copiable.clonable?(Object.new)).to be(true) }
  end

  describe ".duplicable?" do
    it { expect(ZohoCRM::Utils::Copiable.duplicable?(:foo)).to be(false) }
    it { expect(ZohoCRM::Utils::Copiable.duplicable?(nil)).to be(false) }
    it { expect(ZohoCRM::Utils::Copiable.duplicable?(true)).to be(false) }
    it { expect(ZohoCRM::Utils::Copiable.duplicable?(false)).to be(false) }
    it { expect(ZohoCRM::Utils::Copiable.duplicable?(1)).to be(false) }
    it { expect(ZohoCRM::Utils::Copiable.duplicable?(1.0)).to be(false) }
    it { expect(ZohoCRM::Utils::Copiable.duplicable?(Kernel.method(:puts))).to be(false) }

    describe "a frozen String" do
      it { expect(ZohoCRM::Utils::Copiable.duplicable?("a")).to be(true) }
    end

    describe "a mutable String" do
      it { expect(ZohoCRM::Utils::Copiable.duplicable?(+"a")).to be(true) }
    end

    it { expect(ZohoCRM::Utils::Copiable.duplicable?(Object.new)).to be(true) }
  end
end
