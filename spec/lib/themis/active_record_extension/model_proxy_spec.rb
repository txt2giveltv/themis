require 'spec_helper'

describe Themis::ActiveRecordExtension::ModelProxy do
  let(:model)     { stub(:model)                          }
  let(:condition) { lambda { 1 == 1 }                     }
  let(:proxy)     { described_class.new(model, condition) }

  describe '#args_with_condition' do
    it 'do not affect original arguments' do
      original_args = [:email, {:unique => true, :if => :brave? }]
      proxy.send(:args_with_condition, original_args)
      original_args.should == [:email, {:unique => true, :if => :brave? }]
    end
  end
end
