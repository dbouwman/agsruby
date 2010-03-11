# encoding: utf-8

module ArcServer
  module SOAP
    class MapServer < Handsoap::Service
      on_create_document do |doc|
        doc.alias "env", "http://schemas.xmlsoap.org/soap/envelope/"
        doc.alias "ns",  "http://www.esri.com/schemas/ArcGIS/9.3"        
        env = doc.find("Envelope")
        env.set_attr "xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance"        
      end

      def on_before_dispatch
        self.class.endpoint(:uri => @soap_url, :version => 1)
      end

      def initialize(soap_url, protocol_version=2)
        @soap_url = soap_url
      end


      def get_extent_for_parcel(parcel_oid)
        #first get the extent of the parcel in question
        #SOAP Body...
        #<ns:QueryFeatureData>
        #<MapName>Portland</MapName>
        #<LayerID>1</LayerID>
        #<QueryFilter>            
        #    <WhereClause>OBJECTID=100</WhereClause>
        # </QueryFilter>
        #</ns:QueryFeatureData>
        extentResponse = invoke("QueryFeatureData") do |message|
          message.set_attr "xmlns","http://www.esri.com/schemas/ArcGIS/9.2"
          message.add "MapName",'Portland'
          message.add "LayerID",1
          message.add "QueryFilter" do |qf|
            qf.add "SubFields", "Shape"
            qf.add "WhereClause", 'OBJECTID =' + parcel_oid.to_s
          end
        end
        
        extentNode = extentResponse.document.xpath('//Extent',ns).first
        parse_extent(extentNode)
      end
	  
	  
	  def parse_extent(node)
		{
        :x_min => xml_to_int(node, "./XMin/text()"),
        :x_max => xml_to_int(node, "./XMax/text()"),
		    :y_min => xml_to_int(node, "./YMin/text()"),
		    :y_max => xml_to_int(node, "./YMax/text()")          
    }		
	  end
	  
	  def expand_extent(extent, factor)
  		dx = extent[:x_max] - extent[:x_min]
  		offset = dx * factor
  		extent[:x_max] = extent[:x_max] + offset
  		extent[:x_min] = extent[:x_min] - offset
  		extent[:y_max] = extent[:y_max] + offset
  		extent[:y_min] = extent[:y_min] - offset
  		return extent			  
	  end

    def get_parcel_map(parcel_oid)        
  
		    extent = get_extent_for_parcel(parcel_oid)
		    expanded_extent = expand_extent(extent,0.5)
  
        response = invoke("ExportMapImage") do |message|
          message.set_attr "xmlns","http://www.esri.com/schemas/ArcGIS/9.2"
          message.add "MapDescription" do |mapdesc|
            mapdesc.add "Name", 'Portland'
            mapdesc.add "MapArea" do |maparea|
              maparea.set_attr "xsi:type","q1:MapExtent"
              maparea.set_attr "xmlns:q1","http://www.esri.com/schemas/ArcGIS/9.2" 
              
              maparea.add "Extent" do |extent|
                extent.set_attr  "xsi:type","q1:EnvelopeN"
                extent.add "XMin",expanded_extent[:x_min]
                extent.add "YMin", expanded_extent[:y_min]
                extent.add "XMax", expanded_extent[:x_max]
                extent.add "YMax",  expanded_extent[:y_max]                  
              end #extent
            end #maparea
            mapdesc.add "LayerDescriptions" do |layerdescs|
              layerdescs.add "LayerDescription" do |layer0desc|
                layer0desc.add "LayerId",0
                layer0desc.add "Visible", "true"
              end
              layerdescs.add "LayerDescription" do |layer1desc|
                layer1desc.add "LayerId",1
                layer1desc.add "Visible", "true"
                layer1desc.add "SelectionFeatures" do |selectionFeatures|
                  selectionFeatures.add "Int", parcel_oid
                end
              end              
              layerdescs.add "LayerDescription" do |layer2desc|
                  layer2desc.add "LayerId",2
                  layer2desc.add "Visible", "true"
              end  
              layerdescs.add "LayerDescription" do |layer3desc|
                    layer3desc.add "LayerId",3
                    layer3desc.add "Visible", "true"
              end  
              layerdescs.add "LayerDescription" do |layer4desc|
                      layer4desc.add "LayerId",4
                      layer4desc.add "Visible", "true"
              end
            end #end layerdescs
            mapdesc.add "SpatialReference" do |spatialRef|
              spatialRef.set_attr  "xmlns:q10","http://www.esri.com/schemas/ArcGIS/9.2" 
              spatialRef.set_attr  "xsi:type","q10:ProjectedCoordinateSystem"
              spatialRef.add "WKT", 'PROJCS["WGS_1984_Web_Mercator",GEOGCS["GCS_WGS_1984_Major_Auxiliary_Sphere",DATUM["D_WGS_1984_Major_Auxiliary_Sphere",SPHEROID["WGS_1984_Major_Auxiliary_Sphere",6378137.0,0.0]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Mercator"],PARAMETER["False_Easting",0.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",0.0],PARAMETER["Standard_Parallel_1",0.0],UNIT["Meter",1.0]]'
            end
          end #end mapdesc
          message.add "ImageDescription" do |imgdesc|
            imgdesc.set_attr "xmlns",""
            imgdesc.add "ImageType" do |image_type|
              image_type.add "ImageFormat", "esriImagePNG24"
              image_type.add "ImageReturnType", 'esriImageReturnURL'
              
            end #image_type
            imgdesc.add "ImageDisplay" do |image_display|
              image_display.add "ImageHeight", 350
              image_display.add "ImageWidth",450
              image_display.add "ImageDPI",72
            end #image_display
          end #imgdesc
        end #message
        
        #get the image URL from the response
		response.document
        node = response.document.xpath('//ImageURL', ns).first
        #rip out the URL
        xml_to_str(node,'./text()')
      end


      def get_default_map_name
        response = invoke("ns:GetDefaultMapName")
        node = response.document.xpath('//tns:GetDefaultMapNameResponse/Result', ns).first
        parse_default_map_name_result(node)
      end

      def get_legend_info(args = {})
        image_return_type = args[:image_return_url] ? "esriImageReturnURL" : "esriImageReturnMimeData"
        response = invoke("ns:GetLegendInfo") do |message|
          message.add "MapName", args[:map_name] || get_default_map_name
          message.add "ImageType" do |image_type|
            image_type.add "ImageReturnType", image_return_type
            image_type.add "ImageFormat", "esriImagePNG24"
          end
        end
        node = response.document.xpath('//tns:GetLegendInfoResponse/Result', ns).first
        
        parse_legend_info_result(node)
      end

      private
      def ns
        { 'tns', 'http://www.esri.com/schemas/ArcGIS/9.3' }
      end

      # helpers
      def parse_default_map_name_result(node)
        xml_to_str(node, './text()')
      end

      def parse_legend_info_result(node)
        node.xpath('./MapServerLegendInfo', ns).collect { |child| parse_map_server_legend_info(child) }
      end

      def parse_map_server_legend_info(node)
        {
          :layer_id => xml_to_int(node, "./LayerID/text()"),
          :name => xml_to_str(node, "./Name/text()"),
          :legend_groups => node.xpath('./LegendGroups/MapServerLegendGroup', ns).collect { |child| parse_map_server_legend_group(child) }
        }
      end

      def parse_map_server_legend_group(node)
        {
          :heading => xml_to_str(node, "./Heading/text()"),
          :legend_classes => node.xpath("./LegendClasses/MapServerLegendClass", ns).collect { |child| parse_map_server_legend_class(child) }
        }
      end

      def parse_map_server_legend_class(node)
        {
          :label => xml_to_str(node, "./Label/text()"),
          :descriptions => xml_to_str(node, "./Description/text()"),
          :symbol_image => {
            :image_data => xml_to_str(node, "./SymbolImage/ImageData/text()"),
            :image_url  => xml_to_str(node, "./SymbolImage/ImageURL/text()"),
            :image_height => xml_to_int(node, "./SymbolImage/ImageHeight/text()"),
            :image_width => xml_to_int(node, "./SymbolImage/ImageWidth/text()"),
            :image_dpi => xml_to_int(node, "./SymbolImage/ImageDPI/text()")
          },
          :transparent_color => {
            :use_windows_dithering => xml_to_bool(node, "./TransparentColor/UseWindowsDithering/text()"),
            :alpha_value => xml_to_int(node, "./TransparentColor/AlphaValue/text()"),
            :red => xml_to_int(node, "./TransparentColor/Red/text()"),
            :green => xml_to_int(node, "./TransparentColor/Green/text()"),
            :blue => xml_to_int(node, "./TransparentColor/Blue/text()")
          }
        }
      end

    end
  end
end
