module bootstrap/bootstrap-templates

imports elib/elib-bootstrap/lib
imports elib/elib-tablesorter/lib


section templates

  template header1(){ h1{ elements } }
  template header2(){ h2{ elements } }
  template header3(){ h3{ elements } }
  template header4(){ h4{ elements } }
  

  template navigationbar(section: String) {
    template brand(){ navigate root() [class="navbar-brand"] { "Config-Share" } }  
    navbarResponsive{
      navItems{
        // listitem{ navigate administration() { "Adminstration" } }
        // 
        // dropdownInNavbar("Faculty") { 
        // dropdownMenu{
        //     for(f : Faculty) {
        //       dropdownMenuItem{ navigate showFaculty(f) { output(f.name) } }
        //   }
        // }
        // }
      }
      navbarRight{
        signInOut
      }
    }
  }



  template mainIncludes(){
    // includeCSS("adapt.css?2")
    includeCSS("bootstrap/css/bootstrap.min.css?3")
    includeCSS("bootstrap-extension.css?3")
    includeJS( IncludePaths.jQueryJS() )    
    includeJS("bootstrap/js/bootstrap.min.js")
	  tooltipsBS
  }
  
  template bmain(section: String) {
    template fieldset(s : String){
	    controlGroup(s)[all attributes]{ elements }
	  }
    
		mainIncludes 
		  navigationbar(section)    
		  gridContainer{   
		    messages 
		    elements
		    //body()
		  }
  }
  
template signInOut() {
  navItems{
    if(loggedIn()) {
      
        <li class="dropdown">
        <a class="dropdown-toggle" href="#" data-toggle="dropdown">
          output(principal().username)
        </a>
        dropdownMenu{
            dropdownMenuItem[class="dropdown-header"]{ 
              navigate manage-account(principal()) { output(principal().username) }
            }
          dropdownMenuDivider
          dropdownMenuItem{
            signOffLink()
          }
        }
      </li>
    } else {      
      navItem{ navigate( signin( (requestURL() as URL)) )[rel="nofollow"]{ "Sign in" } }
      navItem{ navigate( signup() ){"Sign up"} }
    }
  }
}

template inputTable( selected : Ref<{Entity}>, fromArg : [Entity], pageSize : Int ){
  var from : {Entity} := Set<Entity>()
  var tnamePrefix := id
  
  init{
    from.addAll(selected);
    from.addAll(fromArg);
  }
  
  request var tmpset:= Set<Entity>()
  <input type="hidden" name=tnamePrefix />
  sortedTableBordered( pageSize, from.length ){
    theader{
      th[class="filter-false "]{"Selection"} th{"Options"}
    }
    for( e in from ){
      row{ 
        column {
            makeSortable( if(e in selected) "1" else "0" )
            <input type="checkbox"
              name=tnamePrefix+e.id
              if(e in selected){
                checked="true"
              }
              id=tnamePrefix+e.id
              all attributes
            />
        } column {
                    
             " " outputLabel(e)
          }
        } 
      databind{
        if(getRequestParameter(tnamePrefix+e.id) != null){ tmpset.add(e); }
      }
        
    }
  }
  
  databind{
    if( getRequestParameter(tnamePrefix) != null && tmpset != selected ){
      selected := tmpset;
    }
  }
}


native class javax.servlet.http.HttpServletRequest as HttpServletRequest{
      getRequestURL() : StringBuffer
      getQueryString() : String
  }
  
function requestURL(): String {
  return getDispatchServlet().getRequest().getRequestURL().toString();
}
