module bootstrap/bootstrap-templates

imports elib/elib-bootstrap/lib


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
        navItems{
          // signInOut   
        }
      }
    }
  }



  template mainIncludes(){
    // includeCSS("adapt.css?2")
    includeCSS("bootstrap/css/bootstrap.min.css?3")
    includeCSS("bootstrap-extension.css?3")
    includeJS( IncludePaths.jQueryJS() )    
    includeJS("bootstrap/js/bootstrap.min.js")
  <script>
    jQuery(function() { $(".btn").tooltip({container: 'body'}); } );
  </script>
  }
  
  define bmain(section: String) {

  mainIncludes 
    navigationbar(section)    
    gridContainer{   
      messages 
      elements
      //body()
    }
  }
