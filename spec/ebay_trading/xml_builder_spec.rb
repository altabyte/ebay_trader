# frozen_string_literal: true

require 'ebay_trader/xml_builder'

include EbayTrader

describe XMLBuilder do

  def render_xml?
    true
  end

  def log(xml)
    puts xml if render_xml?
  end

  describe 'Methods' do

    subject(:builder) { XMLBuilder.new }

    it { is_expected.not_to be_nil }
    it { is_expected.to respond_to :root }
    it { is_expected.to respond_to :xml }

    context 'when using missing_method' do
      it { is_expected.to respond_to :SomeEbayXMLElementName }
      it { is_expected.not_to respond_to :an_ebay_element_name_with_underscores }
    end
  end

  describe 'Building XML' do

    context 'when no block is provided' do
      subject(:xml) { XMLBuilder.new.root('Document') }

      it { is_expected.not_to be_nil }
      it { is_expected.to be_a String }
      it { is_expected.to eq '<Document></Document>' }
      it { log xml }
    end


    context 'when providing a basic block' do
      let(:expected_xml) {
        <<XML.strip
<Document>
  <Paragraph>
    <Line>This is the first line</Line>
    <Line>This is the second line</Line>
  </Paragraph>
</Document>
XML
      }

      subject(:xml) do
        XMLBuilder.new(tab_width: 2).root('Document') do
          Paragraph {
            Line 'This is the first line'
            Line 'This is the second line'
          }
        end
      end

      it { is_expected.not_to be_nil }
      it { is_expected.to be_a String }
      it { is_expected.to eq expected_xml }
      it { log xml }
    end


    context 'when providing a blocks with attributes' do
      let(:expected_xml) {
        <<XML.strip
<document xmlns="com:ebay">
  <paragraph style="color:red;">
    <line class="line" data-reference="some reference">This is the first line</line>
    <line class="line">This is the second line</line>
  </paragraph>
</document>
XML
      }

      subject(:xml) do
        XMLBuilder.new(tab_width: 2).root('document', xmlns: 'com:ebay') do
          paragraph style: 'color:red;' do
            line 'This is the first line',  class: 'line', 'data-reference' => 'some reference'
            line 'This is the second line', class: 'line'
          end
        end
      end

      it { is_expected.not_to be_nil }
      it { is_expected.to be_a String }
      it { is_expected.to eq expected_xml }
      it { log xml }
    end


    context 'when adding control structures to the blocks' do
      let(:expected_xml) do
        <<XML.strip
<html>
  <body>
    <h1>Demonstration on how to dynamically build a HTML list</h1>
    <ul>
      <li>Item 0</li>
      <li>Item 1</li>
      <li class="active">Item 2</li>
      <li>Item 3</li>
      <li>Item 4</li>
      <li>Item 5</li>
    </ul>
  </body>
</html>
XML
      end

      subject(:xml) do
        XMLBuilder.new(tab_width: 2).root('html') do
          body do
            h1 'Demonstration on how to dynamically build a HTML list'
            ul do
              (0..5).each { |i|
                if i == 2
                  li "Item #{i}", class: :active
                else
                  li "Item #{i}"
                end
              }
            end
          end
        end
      end

      it { is_expected.not_to be_nil }
      it { is_expected.to be_a String }
      it { is_expected.to eq expected_xml }
      it { log xml }
    end


    context 'when scoping the block' do
      let(:expected_xml) do
        <<XML.strip
<html>
  <body>
    <h1>Document title</h1>
    <div>This is the first paragraph</div>
    <div>This is the second paragraph</div>
  </body>
</html>
XML
      end

      let(:title) { 'Document title' }

      def get_second_paragraph
        'This is the second paragraph'
      end

      subject(:xml) do
        XMLBuilder.new(tab_width: 2).root('html') do |xml|
          xml.body {
            xml.h1 title
            xml.div 'This is the first paragraph'
            xml.div get_second_paragraph
          }
        end
      end

      it { is_expected.not_to be_nil }
      it { is_expected.to be_a String }
      it { is_expected.to eq expected_xml }
      it { log xml }
    end
  end
end