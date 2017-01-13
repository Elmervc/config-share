application configshare

imports config-xml/xml-data

imports bootstrap/bootstrap-templates


entity UploadedFile{
  f : File
}

  page root(){
    var file : File
    bmain("Home"){
	    h5{ "New File" }
	    gridRow{
        gridCol(6){
          panelPrimary("Existing Files"){
            for(uf: UploadedFile order by uf.modified desc){
              navigate derivedScheme(uf){ output(uf.f.getFileName()) }
            }separated-by{ br }
          }
        }
	      gridCol(6){
	        panel("Upload New"){
				    horizontalForm{
				      controlGroup("File"){ input(file) }
				      formActions{
					      submit action{
					      	var uf := UploadedFile{ f := file };
					      	uf.save();
					      }{"Upload"}
				      }
				    }
			    }
			  }

	    }
    }
  }
  
  page derivedScheme(uf : UploadedFile){
    var scheme : XMLScheme
    init{
      scheme := deriveScheme(uf.f);
      rollback();
    }
    
    bmain("Scheme"){
      outputSchemeNode(scheme.rootElem as XMLElem)
    }
  }
  
  template outputSchemeNode(n : XMLElem){
    div[class="elem"]{
      strong{ output(n.tag) }
      for(attr in n.attributes){
        outputSchemeAttr(attr)
      }
      for(child in n.children){
        outputSchemeNode( child )
      }
    }
  }
  template outputSchemeAttr(n : XMLAttr){
    div[class="attr"]{
      strong{ output(n.key) }
      " - "
      emph{
        output(n.description)
	      if(n.description.trim() == ""){
	        "No description"
	      }
	    }
	    if(n.attrValues.length > 0){
	    	div[class="attr-values"]{
	    		"Known Values: "
	    		table{
		    		for(val in n.attrValues){
		    			outputSchemeAttrVal(val)
		    		}
	    		}
	    	}
	    }
    }
  }
  
  template outputSchemeAttrVal(n : XMLAttrValue){
  	row[class="attr-value"]{
  		column{ output(n.val) }
  		column{ 
	  		if(n.siblingAttrVals.length > 0){
	  		    div[class="sibling-attr-values"]{
	  		      for(sib in n.siblingAttrVals){
	  		        output(sib.attr.key) " = \"" output(sib.val) "\""
	  		      }
	  		    }
	  		}
  		}
  	}
  }