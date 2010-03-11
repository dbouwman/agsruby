require 'arcserver'
require 'json'
class ParcelController < ApplicationController
  
  def index
    
    @taxid = params[:id]
    #get the parcel attributes via the REST API
     service = ArcServer::MapServer.new('http://sampleserver1.arcgisonline.com/ArcGIS/services/Portland/ESRI_LandBase_WebMercator/MapServer')
      @jsonString = service.query(1,{:where=>"TLID = '#{@taxid}'",:outFields=>'OBJECTID,TLID,RNO,OWNER1,OWNER2,OWNER3,OWNERADDR,OWNERCITY,OWNERZIP,SITESTRNO,SITEADDR,SITECITY,LANDVAL,BLDGVAL,BLDGSQFT,A_T_ACRES,YEARBUILT,PROP_CODE,LANDUSE,TAXCODE,SALEDATE,SALEPRICE,COUNTY,X_COORD,Y_COORD' })
      @json = JSON.parse(@jsonString)
      @results = @json['features']
      
      if @results.nil? || @results.length == 0
        flash[:notice] = 'No results found.'
      end
    
    #get a map of the request
    @objectId =  @results[0]['attributes']['OBJECTID'].to_s
    @mapUrl = service.get_parcel_map(@objectId)
    
  end
end
