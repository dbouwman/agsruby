require 'arcserver'
require 'json'
class HomeController < ApplicationController


  #Show the index page   
  def index
    #this is not needed
  end
  
  #Show the about page
  def about
    #this is not needed    
  end
  
  def search
    #grab the type and criteria from the params, pass them off to the ESRI Rest API
    #get the response, parse into useful objects, and iterate into the grid
    @searchType = params[:search_type]
    @searchCriteria = params[:search_criteria].upcase
    service = ArcServer::MapServer.new('http://sampleserver1.arcgisonline.com/ArcGIS/services/Portland/ESRI_LandBase_WebMercator/MapServer')
    
    
    @jsonString = service.query(1,{:where=>"#{@searchType} like '%#{@searchCriteria}%'",:outFields=>'TLID, OWNER1,OWNER2,OWNER3,SITEADDR' })
    @json = JSON.parse(@jsonString)
    @results = @json['features']
    
    if @results.nil? || @results.length == 0
      flash[:notice] = 'No results found for search ' + @searchCriteria + ' Please try another search.'
    end
    
    respond_to do |format|
      format.js
    end
    
  end

  

end