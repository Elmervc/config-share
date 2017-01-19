application configshare

imports config-xml/xml-data

imports bootstrap/bootstrap-templates

imports user/user


entity UploadedFile{
  f : File
  doc : XMLDocumentBase
}

access control rules
rule page root(){
  true
}
rule page derivedScheme(uf : UploadedFile, rollback : Bool){
  loggedIn() && principal().isAdmin
}
rule page editor(docInstance : XMLDocInstance){
  docInstance.mayView()
}
rule page downloadXML(docInstance : XMLDocInstance, filename : String){
  docInstance.mayView()
}
rule page browseDoc(base : XMLDocumentBase){
  base.mayView()
}
rule page createBaseDoc(){
  isAdmin()
}
rule template editPanel(base :XMLDocumentBase){
  base.mayEdit()
}
rule template manage(n : XMLElem){
  n.docBase.mayEdit()
}
rule template manage(a : XMLAttr){
  a.docBase.mayEdit()
}
rule page showFork(f : XMLDocInstance){
  f.mayView()
}
rule page newFork(base :XMLDocumentBase){
  base.mayView()
}
section pages

page root(){
  var docs := (from XMLDocumentBase as b where b.archived != true order by b.created desc)
  bmain("Home"){
    gridRow{
      gridCol(6){
        panelPrimary("Configurations"){
          for(b in docs){
            navigate browseDoc(b){ output(b.name) }
          }separated-by{ br }
        }
      }
      gridCol(6){
        
      }
      
    }
  }
}

page browseDoc(base : XMLDocumentBase){
  var forks := (from XMLDocInstance where base = ~base order by modified desc limit 50)
  bmain(""){
    pageHeader{ output(base.name) }
    par{
      output(base.description)
    }
    gridRow{ gridCol(12){
      editPanel(base)
      panel{
        panelHeading{
          iDuplicate " Latest Forks"
        }
        panelBody{
          submit action{ return newFork(base); }{ iPlusSign " Create Fork" }
          if(forks.length < 1){
            "No forks have been created yet"
          }
          else{
            tableBordered{
              for(f in forks){
                row{
                  column{
                    navigate showFork(f){ "view " output(base.name) }
                  } column{
                    "by " output(f.owner.username)
                  } column{
                    "at " output(f.created)
                    if( f.modified.after(f.created) ){
                      " (updated " output(f.modified) ")"
                    }
                  }
                }
              }
            }
          }
        }
      }
      tabsBS([
      ( "Visual Document", { visualDoc(base){} }),
      ( "Pure XML", { pre{ code{ output( base.uploadedFile.f.getContentAsString() ){} } } } )
      ])
      
    } }
    
  }
}

template visualDoc( base : XMLDocumentBase ){
  if(base.mayEdit()){
    horizontalForm{
      outputSchemeNode(base.rootElem, false)
      br
      submit action{}{"Save"}
    }
  } else{
    outputSchemeNode(base.rootElem, false)
  }
}

page showFork(instance : XMLDocInstance){
  bmain(""){
    pageHeader{
      output(instance.name) " by " output(instance.owner.name)
      br small{iDuplicate " forked from " nav(instance.base) }
    }
    panel("Document"){
      instanceEditor(instance)
    }
  }
}

page createBaseDoc(){
  var file : File
  bmain("Create a new base document"){
    panel("Upload New"){
      horizontalForm{
        controlGroup("File"){ input(file) }
        formActions{
          submit action{
            var uf := UploadedFile{ f := file };
            uf.save();
            return derivedScheme(uf, true);
          }{"Upload"}
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
      uf.doc.filename := uf.f.getFileName();
      if(rollback){
        rollback();
      }
    } else{
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

template editPanel(base : XMLDocumentBase){
  init{ if(base.archived == null){ base.archived := false;}}
  panel("Edit Tools"){
    horizontalForm{
      controlGroup("Name") { input(base.name) }
      controlGroup("Description") { input(base.description) }
      controlGroup("Filename") { input(base.filename) }
      controlGroup("Archived"){
        input(base.archived)
        helpBlock{ "An archived base document won't be listed in the libraries anymore. All forks stay accessible" }
      }
      formActions{
        submit action{}{ "Save" }
      }
    }
  }
}

template outputSchemeNode(n : XMLElem, inEditMode : Bool){
  var visible := !inEditMode || n.showInEdit
  div[class="elem visible-" + visible]{
    if(visible){
      strong{ output(n.tag) }
      span[class="text-muted"]{
        output(n.description)
        if(n.unit != ""){
          " Unit: " strong{ output(n.unit) }
        }
      }
      
      if(n.val != ""){
        " "
        if(inEditMode && n.valueEditable){
          if(editInstance.mayEdit()){
            input(n.editInput.val)
          } else{
            output(n.editInput.val)
          }
        } else{
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
      " "
      if(inEditMode && n.valueEditable){
        if(editInstance.mayEdit()){
          input(n.editInput.val)
        } else{
          output(n.editInput.val)
        }
      } else{
        code{ output(n.val) }
      }
      " " span[class="text-muted"]{
        output(n.description)
        if(n.unit != ""){
          " Unit: " strong{ output(n.unit) }
        }
      }
      manage(n)
    }
  }
}

template manage(n : XMLElem){
  gridRow{
    gridCol(3){
      input(n.showInEdit) " Show in Edit"
      if(n.val != "") { br input(n.valueEditable) " Value is Editable" }
      br <small class="text-muted"> "XPath: " output( n.getXPath() ) </small>
      
    } gridCol(9){
      controlGroup("Description"){ input (n.description) }
      controlGroup("Unit"){ input (n.unit) }
    }
  }
}
template manage(n : XMLAttr){
  gridRow{
    gridCol(3){
      input(n.showInEdit) " Show in Edit"
      if(n.val != "") { br input(n.valueEditable) " Value is Editable" }
      br <small class="text-muted"> "XPath: " output( n.getXPath() ) </small>
    } gridCol(9){
      controlGroup("Description"){ input (n.description) }
      controlGroup("Unit"){ input (n.unit) }
    }
  }
}


request var editInstance : XMLDocInstance

template instanceEditor(docInstance : XMLDocInstance){
  init{
    editInstance := docInstance;
    editInstance.init();
  }
  
  template manage(n : XMLElem){}
  template manage(n : XMLAttr){}
  
  gridRow{
    gridCol(12){
      form{
        outputSchemeNode(docInstance.base.rootElem as XMLElem, true)
        br
        // submit action{ return downloadXML(docInstance, docInstance.base.uploadedFile.f.getFileName()); }{"Download XML"}
        submit action{
          var f := docInstance.getXML().asFile( docInstance.base.filename);
          f.download();
        }{"Download XML"}
      }
    }
  }
}

page editor(docInstance : XMLDocInstance){
  var doc := docInstance.base
  
  bmain("Editor"){
    h5{ "Edit " output(docInstance.name) }
    helpBlock{
      output(doc.description)
    }
    instanceEditor(docInstance)
  }
}

page downloadXML(docInstance : XMLDocInstance, filename : String){
  var str := docInstance.getXML();
  mimetype("application/xml")
  
  rawoutput( str )
}

template nav(base : XMLDocumentBase){
  navigate browseDoc(base){ output(base.name) }
}

page newFork(docBase : XMLDocumentBase){
  var fork := XMLDocInstance{
    base := docBase
  }
  bmain("Create new Fork"){
    instanceEditor(fork)
  }
}