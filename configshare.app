application configshare

imports config-group/config-group
imports config-xml/xml-data
imports bootstrap/bootstrap-templates
imports user/user

access control rules
rule page root(){
  true
}
rule page derivedScheme(base : XMLDocumentBase, rollback : Bool){
  loggedIn() && principal().isAdmin
}
rule page editor(docInstance : XMLDocInstance){
  docInstance.mayView()
}
rule page download-xml(docInstance : XMLDocInstance, filename : String){
  docInstance.mayView()
}
rule page browse-doc(base : XMLDocumentBase){
  base.mayView()
}
rule page add-base-doc(){
  isAdmin()
}
rule page browse-group(gr : ConfigGroup, deconame : String){
  gr.mayView()
}
rule template editPanel(base :XMLDocumentBase){
  base.mayEdit()
}
rule template editPanel(gr : ConfigGroup){
  gr.mayEdit()
}
rule template manage(n : XMLElem){
  n.docBase.mayEdit()
}
rule template yourForks(b : XMLDocumentBase){
  loggedIn()
}
rule template instanceEditor(d : XMLDocInstance){
  true
  rule action save(){
   loggedIn() && d.mayEdit() 
  }  
}
rule template manage(a : XMLAttr){
  a.docBase.mayEdit()
}
rule page show-fork(f : XMLDocInstance, decoName : String){
  f.mayView()
}
rule page new-fork(base :XMLDocumentBase){
  base.mayView()
}
rule page new-instance-fork(d : XMLDocInstance){
  d.base.mayView()
}
section pages

page root(){
  var groups := (from ConfigGroup as g where g.archived != true or ~isAdmin() is true order by g.created desc)
    
  bmain("Home"){
    gridRow{
      gridCol(6){
        panelInfo("Device Configurations"){
          for(g in groups){
            wellSmall{
	            navigate browse-group(g, g.name){ output(g.name) }
	            helpBlock{
	              small{ output(g.descr) }
	            }
            }
          }
        }
      }
      gridCol(6){
        if(loggedIn()){
          yourForks( null as XMLDocumentBase )
        }
      }            
    }
    gridRow{ gridCol(12){
      par{
        manageGroups
      }
    }}
  }
}

page browse-group(gr : ConfigGroup, deconame : String){
  var docs := [b | b in gr.baseDocs where b.archived != true order by b.created desc]
  bmain("Browse Group " + gr.name){
    gridRow{
      gridCol(6){
        editPanel(gr)
        panelPrimary("Device Configurations"){
          for(b in docs){
            navigate browse-doc(b){ output(b.name) }
          }separated-by{ br }
        }
      }
      gridCol(6){
        
      }      
    }
  }
}

page browse-doc(base : XMLDocumentBase){
  var forks := (from XMLDocInstance where base = ~base order by modified desc limit 50)
  
  init{
    if(base.filename == null || base.filename == ""){
      base.filename := base.name.replace(".", "-").replace(" ", "-").replace("/", "-");
    }
  }
  
  bmain(""){
    pageHeader{ output(base.name) }
    par{
      output(base.description)
    }
    gridRow{ gridCol(12){
      editPanel(base)
      
      yourForks( base )
            
      panel{
        panelHeading{
          iDuplicate " Latest Forks"
        }
        panelBody{
          par{ submit action{ goto new-fork(base); }{ iPlusSign " Create Fork" } }
          if(forks.length < 1){
            "No forks have been created yet"
          }
          else{
            
            for(f in forks){
              forkRow(f)
            }
            
          }
        }
      }
      tabsBS([
      ( "Visual Document", { visualDoc(base){} }),
      ( "Pure XML", { pre{ code{ output( base.docString ){} } } } )
      ])
      
    } }
    
  }
}

template forkRow(f : XMLDocInstance){
  gridRow{
    gridCol(12){
      navigate show-fork(f, f.name){
        output(f.name2)
       " by " output(f.owner.username)
      }
    // } gridCol(5){
      " at " output(f.created)
      if( f.modified.after(f.created) ){
        " (updated " output(f.modified) ")"
      }
    }
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

page show-fork(instance : XMLDocInstance, decoName : String){
  showForkPageTemplate(instance)
}
template showForkPageTemplate(instance : XMLDocInstance){
  action createFork(){
    goto new-instance-fork(instance);
  }
  
  bmain(""){
    pageHeader{
      output(instance.name2)
      " by "
      if(instance.owner == null || (loggedIn() && principal() == instance.owner) ){
        "You"
      } else {
        output(instance.owner.name)
      }
      br small{iDuplicate " forked from " nav(instance.base) }
    }
    if(instance.owner != null) { par{ submit createFork()[title="A fork will be a personal copy which you can edit, save and share"]{ iDuplicate " Create Your Fork" } } }
    helpBlock{ output(instance.descr) }
    panel("Document"){
      instanceEditor(instance)
    }
  }
}

page add-base-doc(){
  var file : File
  var newBase := XMLDocumentBase{}
  bmain("Create a new base document"){
    panel("Upload New"){
      horizontalForm{
        controlGroup("Name"){ input(newBase.name) }
        controlGroup("Description"){ input(newBase.description) }
        controlGroup("Archived"){ input(newBase.archived) " archived" }
        controlGroup("Select Group (optional)"){
          input(newBase.configGroup)
        }
        controlGroup("File (upload)"){ input(file) }
        controlGroup("File (c/p)"){
          input(newBase.docString)
        }
        
        
        formActions{
          submit action{
            if(file != null){
              newBase.docString := file.getContentAsString();
            }
            
            newBase.save();
            return derivedScheme(newBase, true);
          }{"Upload"}
        }
      }
    }
  }
}


page derivedScheme(base : XMLDocumentBase, review : Bool){
  var instances : [XMLDocInstance]
  init{
    if(base.rootElem == null){
      base.deriveScheme();
      if(review){
        rollback();
      }
    } else{
      instances := from XMLDocInstance as ins where ins.base = ~base order by created desc;
    }
  }
  action doDeriveScheme(){
    return derivedScheme(base, false);
  }
  
  bmain("Scheme"){
    horizontalForm{
      if(!review){
	      panel("Document Base Settings"){
	        controlGroup("Name"){ input(base.name) }
	        controlGroup("Description"){ input(base.description) }
	        
	        formActions{
	          submit action{}{ "Save" } br
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
	          submit action{ goto new-fork(base); }[title="A fork will be a personal copy which you can edit, save and share"]{ iPlusSign " Create Fork" }
	        }
	      }
      }
      outputSchemeNode(base.rootElem as XMLElem, false)
      if(review){
        submit doDeriveScheme(){
          "This looks Okay, save the scheme"
        }
      }
    }
  }
}

template editPanel(gr : ConfigGroup){
  var allowed := (from XMLDocumentBase order by created desc)
  
  action addBaseDoc(){
    goto add-base-doc();
  }
  
  panel("Edit Tools"){
    horizontalForm{
      controlGroup("Name") { input(gr.name) }
      controlGroup("Description") { input(gr.descr) }
      controlGroup("Archived"){
        input(gr.archived)
        helpBlock{ "An archived base document won't be listed in the libraries anymore." }
      }
      controlGroup("XML Documents"){
        submit addBaseDoc() { iPlus " New Base Document"}
        inputTable(gr.baseDocs, allowed, 50)
      }
      formActions{
        submit action{}{ "Save" }
      }
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
          gridRow{ gridCol(6){
	          if(editInstance.mayEdit()){
	            input(n.editInput.val)
	          } else{
	            output(n.editInput.val)
	          }
	        } gridCol(6){
	          "Original: "
	          code{ output(n.val) }
          } }
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
        gridRow{ gridCol(6){
          if(editInstance.mayEdit()){
            input(n.editInput.val)
          } else{
            output(n.editInput.val)
          }
        } gridCol(6){
          "Original: "
          code{ output(n.val) }
        } }
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
  
  action save(){
    if(docInstance.owner == null){
      docInstance.owner := principal();
    }
    goto show-fork(docInstance, docInstance.name2);
  }
  
  action download(){
    var f := docInstance.getXML().asFile(docInstance.base.filename);
    getPage().setMimetype("text/xml");
    f.download();    
    if(!docInstance.mayEdit()){
      rollback();
    }
  }
  
  gridRow{
    gridCol(12){
      form{
        outputSchemeNode(docInstance.base.rootElem as XMLElem, true)
        br
        if(loggedIn()){
          if(docInstance.mayEdit()){
            controlGroup("Name"){ input(docInstance.name) }
            controlGroup("Description"){ input(docInstance.descr) }
          }
        }
        
        if(!loggedIn() && docInstance.mayEdit()){
          helpBlock{ 
            iInfoSign " " navigate signin( requestURL() as URL){"Sign in"} " or " navigate signup(){"register"} " to save/share your fork."
          }
        }
        
        formActions{
          submit save(){ iFloppyDisk " Save" }" " 
          submit download(){ iDownload " Download XML"}
        }
      }
    }
  }
}

template yourForks(base : XMLDocumentBase){
  var forks : [XMLDocInstance]
  init{
    if(base == null){
      forks := from XMLDocInstance as f where f.owner = ~principal();
    } else {
      forks := from XMLDocInstance as f where f.base=~base and f.owner = ~principal();
    }
   }
  
  if(forks.length > 0){
    panelPrimary("Your Forks"){
      for(f in forks order by f.modified desc){
        forkRow(f)
      }
    }
  }
}


page editor(docInstance : XMLDocInstance){
  var doc := docInstance.base
  
  bmain("Editor"){
    h5{ "Edit " output(docInstance.name2) }
    helpBlock{
      output(doc.description)
    }
    instanceEditor(docInstance)
  }
}

page download-xml(docInstance : XMLDocInstance, filename : String){
  var str := docInstance.getXML()
  mimetype("application/xml")
  
  rawoutput( str )
}

template nav(base : XMLDocumentBase){
  navigate browse-doc(base){ output(base.name) }
}

page new-instance-fork(ins : XMLDocInstance){
  var fork := ins.createFork()
  
  showForkPageTemplate(fork)
}

page new-fork(docBase : XMLDocumentBase){
  var fork := XMLDocInstance{
    base := docBase
  }
  showForkPageTemplate(fork)
}