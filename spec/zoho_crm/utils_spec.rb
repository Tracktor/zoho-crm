# frozen_string_literal: true

RSpec.describe ZohoCRM::Utils do
  describe ".normalize_options" do
    it "requires an argument", aggregate_failures: true do
      expect { described_class.normalize_options }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { described_class.normalize_options(nil) }.to_not raise_error
    end

    context "when the options argument is not a Hash (or can't be turned into one)" do
      it "raises an error", aggregate_failures: true do
        options = 42

        expect { described_class.normalize_options(options) }
          .to raise_error(TypeError, "no implicit conversion of #{options.class} into Hash")

        expect { described_class.normalize_options({}) }.to_not raise_error
        expect { described_class.normalize_options([]) }.to_not raise_error
        expect { described_class.normalize_options(nil) }.to_not raise_error
      end
    end

    context "when the options argument is not a Hash" do
      it "is converted to a Hash" do
        expect(described_class.normalize_options([])).to be_a(Hash)
      end
    end

    context "when the options argument is a Hash" do
      it "converts all keys to strings" do
        options = described_class.normalize_options({foo: 42, bar: 73})

        expect(options.keys.all? { |k| String === k }).to be(true)
      end

      it "removes keys with nil values" do
        options = described_class.normalize_options({foo: 42, bar: false, baz: "", qux: nil})

        expect(options.keys).to eq(%w[foo bar baz])
      end

      context "when a value is a Symbol" do
        specify "it is converted to a String" do
          options = described_class.normalize_options({foo: :bar})

          expect(options["foo"]).to eq("bar")
        end
      end

      context "when a value is a String" do
        specify "its leading and trailing whitespace is removed" do
          options = described_class.normalize_options({foo: "   42   "})

          expect(options["foo"]).to eq("42")
        end
      end

      context "when a value is an Array" do
        specify "duplicate elements are removed" do
          options = described_class.normalize_options({foo: [:bar, :bar, "baz"]})

          expect(options["foo"]).to eq([:bar, "baz"])
        end

        specify "nil values are removed" do
          options = described_class.normalize_options({foo: [:bar, nil, "baz"]})

          expect(options["foo"]).to eq([:bar, "baz"])
        end
      end

      context "when a value is a Hash" do
        specify "keys with nil values are removed" do
          options = described_class.normalize_options({foo: {bar: 42, baz: nil}})

          expect(options["foo"]).to eq({bar: 42})
        end
      end
    end
  end

  describe ".jsonify" do
    it "requires an argument", aggregate_failures: true do
      expect { described_class.jsonify }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { described_class.jsonify(nil) }.to_not raise_error
    end

    context "when the value is a Symbol" do
      it "is converted to a String" do
        expect(described_class.jsonify(:foo)).to be_a(String).and eq("foo")
      end
    end

    context "when the value is a Float" do
      context "when the value is finite" do
        it "is returned as is" do
          expect(described_class.jsonify(3.14)).to be_a(Float).and eq(3.14)
        end
      end

      context "when the value represents infinity" do
        it "returns nil" do
          expect(described_class.jsonify(Float::INFINITY)).to be_nil
        end
      end
    end

    context "when the value is a BigDecimal" do
      context "when the value is finite" do
        it "is converted to a String" do
          expect(described_class.jsonify(BigDecimal(42))).to be_a(String).and eq("0.42e2")
        end
      end

      context "when the value represents infinity" do
        it "returns nil" do
          expect(described_class.jsonify(BigDecimal::INFINITY)).to be_nil
        end
      end
    end

    context "when the value is an Array" do
      it "calls .jsonify on each element", aggregate_failures: true do
        allow(described_class).to receive(:jsonify).and_call_original

        array = [:foo, Float::INFINITY, BigDecimal(42)]
        json_array = ["foo", nil, "0.42e2"]

        expect(described_class.jsonify(array)).to eq(json_array)
        expect(described_class).to have_received(:jsonify).exactly(array.size + 1).times
        expect(described_class).to have_received(:jsonify).with(:foo)
        expect(described_class).to have_received(:jsonify).with(Float::INFINITY)
        expect(described_class).to have_received(:jsonify).with(BigDecimal(42))
      end
    end

    context "when the value is a Hash" do
      it "converts all keys to strings" do
        hash = described_class.normalize_options({foo: 42, bar: 73})

        expect(hash.keys.all? { |k| String === k }).to be(true)
      end

      it "calls .jsonify on each value", aggregate_failures: true do
        allow(described_class).to receive(:jsonify).and_call_original

        hash = {foo: :crazy, bar: Float::INFINITY, baz: BigDecimal(42)}
        json_hash = {"foo" => "crazy", "bar" => nil, "baz" => "0.42e2"}

        expect(described_class.jsonify(hash)).to eq(json_hash)
        expect(described_class).to have_received(:jsonify).exactly(hash.keys.size + 1).times
      end
    end

    context "when the value is an Enumerable" do
      it "is converted to an Array" do
        expect(described_class.jsonify(1..3)).to be_an(Array)
      end

      it "calls .jsonify on the Array representation", aggregate_failures: true do
        allow(described_class).to receive(:jsonify).and_call_original

        expect(described_class.jsonify(1..3)).to eq([1, 2, 3])

        # 1 time with the range, 1 time with the array and 1 time with each element
        expect(described_class).to have_received(:jsonify).exactly(5).times
      end
    end

    context "when the value is a Time" do
      it "is converted to a String" do
        expect(described_class.jsonify(Time.now)).to be_an(String)
      end

      it "is formatted to the ISO8601 format", aggregate_failures: true do
        expect(described_class.jsonify(Time.utc(2048, 1, 2, 3, 4, 5))).to eq("2048-01-02T03:04:05Z")
        expect(described_class.jsonify(Time.new(2048, 1, 2, 3, 4, 5, "-06:00"))).to eq("2048-01-02T03:04:05-06:00")
      end
    end

    context "when the value is a Date" do
      it "is converted to a String" do
        expect(described_class.jsonify(Date.today)).to be_an(String)
      end

      it "is formatted to the ISO8601 format" do
        expect(described_class.jsonify(Date.new(2048, 1, 2))).to eq("2048-01-02")
      end
    end

    context "when the value is a DateTime" do
      it "is converted to a String" do
        expect(described_class.jsonify(DateTime.now)).to be_an(String)
      end

      it "is formatted to the ISO8601 format" do
        expect(described_class.jsonify(DateTime.new(2048, 1, 2, 3, 4, 5, "-06:00"))).to eq("2048-01-02T03:04:05-06:00")
      end
    end

    context "when the value is not JSON-compatible" do
      it "is returned as is" do
        object = Class.new
        expect(described_class.jsonify(object)).to eq(object)
      end
    end
  end
end
