module config-group/config-group

section entities

entity ConfigGroup{
  name       : String
  baseDocs   : {XMLDocumentBase}
  descr      : WikiText
  archived   : Bool (default=true)
}

extend entity XMLDocumentBase{
  configGroup : ConfigGroup (inverse=baseDocs)
}

access control rules
rule template manageGroups(){
  isAdmin()
}
section templates

template manageGroups(){
  var allGroups := (from ConfigGroup as gr order by gr.created desc)
  
  action newConfigGroup(){
    var new := ConfigGroup{
      name := "CHANGE_ME"
    };
    new.save();
    goto browse-group(new, "new-group");
  }  
  
  panel("Configuration Groups"){
  	gridRow{
  		gridCol(2){ "Name" }
  		gridCol(4){ "Description" }
  		gridCol(1){ "Archived" }
  	}
    for(gr in allGroups){
      gridRow{
		    gridCol(2){
		      navigate browse-group(gr, gr.name){ output(gr.name) }
		    }
		    gridCol(4){ output(gr.descr)  }
		    gridCol(1){ output(gr.archived) }
		  }
    }
    
    if(isAdmin()){
      submit newConfigGroup(){ iPlus " Add Configuration Group"}
    }
  }
}