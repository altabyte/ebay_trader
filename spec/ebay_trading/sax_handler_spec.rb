# frozen_string_literal: true

require 'json'
require 'ox'
require 'ebay_trader/sax_handler'

include EbayTrader

describe SaxHandler do

  let(:xml) do
    <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<GetItemResponse xmlns="urn:ebay:apis:eBLBaseComponents">
  <Item>
    <StartPrice currencyID="USD">24.99</StartPrice>
    <Percent>30.0</Percent>
    <PictureDetails>
      <GalleryType>Gallery</GalleryType>
      <GalleryURL>http://i.ebayimg.com/00/s/MTI4MFgxMjgw/z/JqwAAOSwajVUODlI/$_1.JPG?set_id=880000500F</GalleryURL>
      <PhotoDisplay>PicturePack</PhotoDisplay>
      <PictureURL>http://i.ebayimg.com/00/s/MTI4MFgxMjgw/z/JqwAAOSwajVUODlI/$_1.JPG?set_id=880000500F</PictureURL>
      <PictureURL>http://i.ebayimg.com/00/s/MTI4MFgxMjgw/z/ibIAAOSw8cNUODlL/$_1.JPG?set_id=880000500F</PictureURL>
      <PictureURL>http://i.ebayimg.com/00/s/MTI4MFgxMjgw/z/cjsAAOSwY45UODlP/$_1.JPG?set_id=880000500F</PictureURL>
    </PictureDetails>
  </Item>
</GetItemResponse>
    XML
  end

  describe 'HashWithIndifferentAccess.deep_find' do

    subject(:hash) do
      handler = SaxHandler.new
      Ox.sax_parse(handler, StringIO.new(xml), convert_special: true)
      handler.to_hash
    end

    it { is_expected.not_to be_nil }
    it { is_expected.to be_a(Hash) }
    it { is_expected.to be_a(HashWithIndifferentAccess) }
    it { is_expected.to respond_to :deep_find }
    it { puts JSON.pretty_generate hash }

    it 'Should find a deeply nested element using deep_find' do
      picture_details = hash.deep_find([:get_item_response, :item, :picture_details])
      expect(picture_details).not_to be_nil
      expect(picture_details).to be_a HashWithIndifferentAccess
      [:gallery_type, :gallery_url, :photo_display, :picture_url].each do |key|
        expect(picture_details).to have_key(key)
      end

      picture_url = picture_details.deep_find(:picture_url)
      expect(picture_url).not_to be_nil
      expect(picture_url).to be_a Array
      expect(picture_url.count).to eq(3)
    end

    it 'should return the default value if path  is not found' do
      default = 'DEFAULT'.freeze
      element = hash.deep_find([:get_item_response, :element_does_not_exist], default)
      expect(element).not_to be_nil
      expect(element).to eq(default)
    end
  end


  describe 'Price types' do

    let(:start_price) { hash.deep_find([:get_item_response, :item, :start_price]) }
    let(:start_price_currency) { hash.deep_find([:get_item_response, :item, :start_price_currency]) }
    let(:percent) { hash.deep_find([:get_item_response, :item, :percent]) }

    context 'Default - BigDecimal' do

      before { EbayTrader.configuration.price_type = nil } # Defaults to BigDecimal

      subject(:hash) do
        handler = SaxHandler.new
        Ox.sax_parse(handler, StringIO.new(xml), convert_special: true)
        handler.to_hash
      end

      it { expect(EbayTrader.configuration.price_type).to eq(:big_decimal) }
      it { expect(start_price).to be_a(BigDecimal) }
      it { expect(start_price).to eq(BigDecimal.new('24.99')) }

      it { expect(start_price_currency).not_to be_nil }
      it { expect(start_price_currency).to eq('USD') }
      it { expect(percent).to be_a(Float) }
    end


    context 'Float' do

      before { EbayTrader.configuration.price_type = :float }

      subject(:hash) do
        handler = SaxHandler.new
        Ox.sax_parse(handler, StringIO.new(xml), convert_special: true)
        handler.to_hash
      end

      it { expect(EbayTrader.configuration.price_type).to eq(:float) }
      it { expect(start_price).to be_a(Float) }
      it { expect(start_price).to eq(24.99) }

      it { expect(start_price_currency).not_to be_nil }
      it { expect(start_price_currency).to eq('USD') }
      it { expect(percent).to be_a(Float) }
    end


    context 'Fixnum' do

      before { EbayTrader.configuration.price_type = :fixnum }

      subject(:hash) do
        handler = SaxHandler.new
        Ox.sax_parse(handler, StringIO.new(xml), convert_special: true)
        handler.to_hash
      end

      it { expect(EbayTrader.configuration.price_type).to eq(:fixnum) }
      it { expect(start_price).to be_a(Fixnum) }
      it { expect(start_price).to eq(2499) }

      it { expect(start_price_currency).not_to be_nil }
      it { expect(start_price_currency).to eq('USD') }
      it { expect(percent).to be_a(Float) }
    end
  end


  context 'When there is an array mixed in a list of nodes' do

    subject(:handler) do
      handler = SaxHandler.new
      Ox.sax_parse(handler, StringIO.new(xml), convert_special: true)
      handler
    end

    it { expect(handler).not_to be_nil }
    it { expect(handler.to_hash).not_to be_nil }
    it { puts JSON.pretty_generate handler.to_hash }

    let(:picture_url) { handler.to_hash[:get_item_response][:item][:picture_details][:picture_url] }

    it 'Has an array of 3 photo URLs' do
      expect(picture_url).not_to be_nil
      expect(picture_url).to be_a(Array)
      expect(picture_url.length).to eq(3)
    end

  end

end

