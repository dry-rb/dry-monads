# frozen_string_literal: true

RSpec.describe(Dry::Monads::Lazy) do
  mixin = Dry::Monads::Lazy::Mixin
  include mixin

  subject { Lazy { 1 + 2 } }

  it_behaves_like "a monad"

  describe "#value!" do
    it "forces the computation" do
      run = false
      m = Lazy { run = true }

      expect(run).to be(false)
      m.value!
      expect(run).to be(true)
    end

    it "runs the computation on the current thread" do
      expect(Lazy { Thread.current }.value!).to be(Thread.main)
    end
  end

  describe "#force!" do
    it "is an alias for #value!" do
      expect(subject.method(:force!)).to eql(subject.method(:value!))
    end
  end

  describe "#force" do
    it "is an exception-safe version of force!" do
      forced = false
      m = Lazy { forced = true; 1 / 0 }

      expect { m.force }.not_to raise_error
      expect(forced).to be(true)
    end
  end

  describe "#fmap" do
    it "transforms the underlying value" do
      expect(subject.fmap { |x| x * 2 }.value!).to be(6)
    end

    it "guarantees a single run" do
      eff = 0
      m = subject.fmap { eff += 1 }
      expect(m.value!).to be(1)
      expect(m.value!).to be(1)
      expect(eff).to be(1)
    end

    it "delays the execution until the result is required" do
      eff = 0
      m = subject.fmap { eff += 1 }.fmap { eff += 1 }
      expect(eff).to be(0)
      m.force
      expect(eff).to be(2)
    end
  end

  describe "#bind" do
    it "composes computations" do
      expect(subject.bind { |x| Lazy { x * 2 } }.value!).to be(6)
    end
  end

  describe "#to_s" do
    it "introspects the value" do
      expect(subject.to_s).to eql("Lazy(?)")

      subject.value!
      expect(subject.to_s).to eql("Lazy(3)")

      expect(Lazy { 1 / 0 }.force.to_s).to eql("Lazy(!#<ZeroDivisionError: divided by 0>)")
    end
  end

  describe "#discard" do
    it "nullifies the value" do
      expect(Lazy { 1 }.discard.value!).to be mixin::Unit
    end
  end
end
