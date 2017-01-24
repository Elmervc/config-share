module user/user

imports elib/elib-authentication/lib

section access control functions

extend entity ConfigGroup{
  function mayView() : Bool{
    return !archived || isAdmin();
  } 
  function mayEdit() : Bool{
    return isAdmin();
  }
}

extend entity XMLDocumentBase{
  function mayView() : Bool{
    return true;
  } 
  function mayEdit() : Bool{
    return loggedIn() && principal() == this.owner || isAdmin();
  }
}

extend entity XMLDocInstance{
  function mayView() : Bool{
    return true;
  } 
  function mayEdit() : Bool{
    return this.owner == null || loggedIn() && principal() == this.owner || isAdmin();
  }
}

function isAdmin() : Bool{
  return loggedIn() && principal().isAdmin;
}
section app-specific config

function HOMEPAGE_URL() : URL{
	return "http://config-share.codefinder.org";
}

function FROM_EMAIL() : Email{
	return "noreply@codefinder.org";
}

function USER_REG_EXPIRATION_HOURS() : Int{
	return 48;
}
function RESET_PASS_EXPIRATION_HOURS() : Int{
  return 2;
}
extend entity User{
  ownedInstances : [XMLDocInstance]
  ownedDocBases  : [XMLDocumentBase]
  
  isAdmin : Bool (default=false)
}

function principal() : User{
  return securityContext.principal;
}

section pages

override page confirm-registration(reg : UserAccountRequest){
	bmain( reg.actionString() ){		
		pageHeader{ output(reg.actionString())	}
		userAccountRequestForm(reg)[class="form-horizontal"]		
	}
}

override page signup(){
  bmain("User Registration"){
    pageHeader{ "Register" }
    registerUserForm[class="form-horizontal"]    
  }
}

override page reset-password(n : NewPassword){
  bmain("Reset password"){
    pageHeader{"Reset password for user: " output(n.user.username) }
    gridRow{ gridSpan(12){
      resetPasswordForm(n)[class="form-horizontal"]
    } }
  }
}

override page forgot-password(eml : Email){
  bmain("Forgot password"){
    pageHeader{ "Forgot password" }
    gridRow{
      gridSpan(12) {
        forgotPasswordForm(eml)[class="form-horizontal"]
      }
    }
  }
}

override page signin(from : URL) {
  bmain("Sign In"){
    pageHeader{ "Sign In" }
    loginForm(from)[class="form-horizontal"]
  }
}

override page manage-account(u : User){
  bmain("Manage Account"){
   pageHeader{ "Manage Account - " output(u.username) }
   manageAccountForm(u)[class="form-horizontal"] 
  }
}
