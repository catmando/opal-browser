require 'spec_helper'

describe Browser::NativeCachedWrapper do
  it 'deduplicates DOM objects' do
    expect($document.at_css("body").hash).to eq($document.body.hash)
    expect($document.body.hash).not_to eq($document.body.dup.hash) # Should dup/clone have different semantics?
    expect($document.body.hash).not_to eq($document.head.hash)
  end

  it 'accurately intercepts the last new call' do
    class Demo
      include Browser::NativeCachedWrapper

      def self.new(arg1, arg2)
        super(`{arg1: #{arg1}, arg2: #{arg2}}`)
      end

      def data
        [:data, `#@native.arg1`, `#@native.arg2`]
      end
    end

    class SuperDemo < Demo
      def self.new(arg1, arg2, arg3)
        super("superdemo", "#{arg1} - #{arg2} - #{arg3}")
      end
    end

    expect(Demo.new("a", "b").data).to eq([:data, "a", "b"])
    expect(SuperDemo.new("1", "2", "3").data).to eq([:data, "superdemo", "1 - 2 - 3"])
  end

  html <<-HTML
    <iframe id='ifr' src='about:blank' sandbox=''></iframe>
  HTML

  it 'supports restricted objects', :requires_server do
    # Window won't be restricted
    expect($window.restricted?).to eq(false)
    # Iframe itself won't be restricted
    expect($document['ifr'].restricted?).to eq(false)
    # But its content_window will be (due to CORS)  (this only works on a real browser)
    expect($document['ifr'].content_window.restricted?).to eq(true)
  end
end
