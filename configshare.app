application configshare

imports config-xml/xml-data

imports bootstrap/bootstrap-templates


entity UploadedFile{
  f : File
  doc : XMLDocumentBase
}

  page root(){
    var file : File
    bmain("Home"){
	    h5{ "New File" }
	    gridRow{
        gridCol(6){
          panelPrimary("Existing Files"){
            for(uf: UploadedFile order by uf.modified desc){
              navigate derivedScheme(uf, true){ output(uf.f.getFileName()) }
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
  
  page derivedScheme(uf : UploadedFile, rollback : Bool){
    var instances : [XMLDocInstance]
    init{
      if(uf.doc == null){
	      uf.doc := deriveScheme(uf.f);
	      if(rollback){
	        rollback();
	      }
      } else {
        instances := from XMLDocInstance as ins where ins.base = ~uf.doc order by created desc;
      }
    }
    
    action save(){
      uf.doc.uploadedFile := uf;
      
      // uf.doc.save();
    }
    action createInstance(){
      var instance := XMLDocInstance{
        base := uf.doc
      };
      instance.save();
      return editor(instance);
    }
    
    bmain("Scheme"){
      horizontalForm{
      panel("New Scheme Settings"){
        controlGroup("Name"){ input(uf.doc.name) }
        controlGroup("Description"){ input(uf.doc.description) }
        
        formActions{
          submit save(){ "Save" } br
        }
        panel("Instances (forks)"){
          for(ins in instances){
            "Instance created " output(ins.created)
            if( ins.modified.after(ins.created) ){
              small{ " Last edited " output(ins.modified) }
            }
            " "
            navigate editor(ins){ "edit" }
          }separated-by{ br }
          par{ submit createInstance(){ iPlus "New Instance" } }
        }
      }
      
      outputSchemeNode(uf.doc.rootElem as XMLElem, false)
      }
    }
  }
  
  template outputSchemeNode(n : XMLElem, inEditMode : Bool){
    var visible := !inEditMode || n.showInEdit
    div[class="elem visible-" + visible]{
      if(visible){
	      strong{ output(n.tag) }
	      " " span[class="text-muted", title="XPath: "  + n.getXPath()]{ " " iInfoSign }
	      span[class="text-muted"]{ output(n.description) }
	      if(n.val != ""){
	        " "
	        if(inEditMode && n.valueEditable){
	          input(n.val)
	        } else {
	          code{ output(n.val) }
	        }
	      }
	      manage(n)
      }
      
      for(attr in n.attributes){
        outputSchemeAttr(attr, inEditMode)
      }
      for(child in n.children){
        outputSchemeNode( child, inEditMode )
      }
    }
  }
  
  template outputSchemeAttr(n : XMLAttr, inEditMode : Bool){
    var visible := !inEditMode || n.showInEdit
    div[class="attr visible-" + visible]{
      if(visible){
	      strong{ output(n.key) }
	      " " span[class="text-muted", title="XPath: "  + n.getXPath()]{ " " iInfoSign }
	      " "
	      if(inEditMode && n.valueEditable){
	        input(n.editInput.val)
	      } else {
	        code{ output(n.val) }
	      }
	      " " span[class="text-muted"]{
	        output(n.description)
		    }
		    manage(n)
	    }
    }
  }
  
  template manage(n : XMLElem){
    gridRow{
      gridCol(3){
	      input(n.showInEdit) " Show in Edit" " "
	      if(n.val != "") { input(n.valueEditable) " Value is Editable" }
      } gridCol(9){
        controlGroup("Description"){ input (n.description) }
        controlGroup("Unit"){ input (n.unit) }
      }
    }
  }
  template manage(n : XMLAttr){
    gridRow{
      gridCol(3){
		    input(n.showInEdit) " Show in Edit"  " "
		    if(n.val != "") { input(n.valueEditable) " Value is Editable" }
	    } gridCol(9){
	      controlGroup("Description"){ input (n.description) }
	      controlGroup("Unit"){ input (n.unit) }
	    }
	  }
  }
  
  
  request var editInstance : XMLDocInstance
  
  page editor(docInstance : XMLDocInstance){
    var doc := docInstance.base
    
    template manage(n : XMLElem){}
    template manage(n : XMLAttr){}
    
    init{
      editInstance := docInstance;
      editInstance.init();
    }
    
    bmain("Editor"){
      h5{ "Edit " output(doc.name) }
      helpBlock{
        output(doc.description)
      }
      gridRow{
        gridCol(12){
          form{
            outputSchemeNode(doc.rootElem as XMLElem, true)
            br
            submit action{ return downloadXML(docInstance, docInstance.base.uploadedFile.f.getFileName()); }{"Download XML"}
          }
        }
      }
    }
  }
  
  page downloadXML(docInstance : XMLDocInstance, filename : String){
    var str := docInstance.getXML();
    mimetype("application/xml")
    
    rawoutput( str )
  }