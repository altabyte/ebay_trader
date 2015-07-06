require 'json'
require 'ox'
require 'ebay_trading/sax_handler'

include EbayTrading

describe SaxHandler do


  context 'When there is an array mixed in a list of nodes' do

    # XML has multiple PictureURL elements mixed in PictureDetails
    let(:xml) do
      <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<GetItemResponse xmlns="urn:ebay:apis:eBLBaseComponents">
  <Item>
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

