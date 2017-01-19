module config-xml/xml-data

entity XMLDocumentBase{
  rootElem : RootXMLElem (inverse=scheme)
  name : String
  description : WikiText
  uploadedFile : UploadedFile
  owner : User
  filename : String
  archived : Bool

}

entity XMLElem{
  tag : String
  description : WikiText
  unit : String
  children : List<XMLElem>
  attributes : List<XMLAttr> (inverse=elem)
  parent  : XMLElem (inverse=children)
  childNumber : Int
  val : Text
  xpath : String := getXPath()
  
  showInEdit : Bool (default=false)
  valueEditable : Bool (default=false)
  editInput : XMLDocInput := getEditInput()
  editInputInternal : XMLDocInput (transient)
  
  docBase : XMLDocumentBase (cache) := getDocBaseInternal()
  
  function getDocBaseInternal() : XMLDocumentBase{
    return parent.docBase;
  }
  function getEditInput() : XMLDocInput{
    if(editInputInternal == null){
      editInputInternal := XMLDocInput{
        xmlElem := this
      };
      editInstance.inputs.add(editInput);
    }
    return editInputInternal;
  }
  
  function getXPath() : String{
    var xpath := "";
    if(parent != null){
      xpath := parent.getXPath();
    }
    return xpath + "/" + "*" + "[" + childNumber + "]";
  }
  function deriveMeFrom(n : XMLNode, childNumber : Int){
    tag := n.getNodeName();
    this.childNumber := childNumber;
    var attCnt := 1; 
    for(xmlAttr in n.getAttributes()){
    	var attr := XMLAttr{};
      attributes.add(attr);    	
    	attr.deriveMeFrom(xmlAttr, attCnt);
    	attCnt := attCnt + 1;    
    }
    
    var idx := 1;
    for(child in n.getChildren()){
    	var childElem := XMLElem{};
  		children.add(childElem);
      childElem.deriveMeFrom( child, idx);
      idx := idx + 1;
    }
    if(idx < 2){
      val := n.getVal();
    }
  }
  
  function editableItems( list : [Entity] ){
    if(this.showInEdit){
      list.add(this);
    }
    for(attr in attributes where attr.showInEdit){
      list.add(attr);
    }
    for(child in children){
      child.editableItems(list);
    }
  }
  
  extend function setValueEditable(f : Bool){
    if(f){
      showInEdit := true;
    }
  }
}

entity RootXMLElem : XMLElem{
  scheme : XMLDocumentBase
  
  function getXPath() : String{ return ""; }
  function getDocBaseInternal() : XMLDocumentBase{
    return scheme;
  } 
}

entity XMLAttr{
  elem : XMLElem
  key : String
  val : Text
  description : WikiText
  unit : String
  childNumber : Int
  
  editInput : XMLDocInput := getEditInput()
  editInputInternal : XMLDocInput (transient)
  docBase : XMLDocumentBase := elem.docBase
  
  
  function getEditInput() : XMLDocInput{
    if(editInputInternal == null){
      editInputInternal := XMLDocInput{
        xmlAttr := this
      };
      editInstance.inputs.add(editInput);
    }
    return editInputInternal;
  }
  
  showInEdit : Bool (default=false)
  valueEditable : Bool (default=false)
  // attrValues : List<XMLAttrValue> (inverse=attr)
  
  function getXPath() : String{
    var xpath := elem.getXPath();
    return xpath + "/@" + key;
  }
  
  function deriveMeFrom(n : XMLNode, childNumber : Int){
    key := n.getNodeName();
    val := n.getVal();
    this.childNumber := childNumber;
  }
  
  extend function setValueEditable(f : Bool){
    if(f){
      showInEdit := true;
    }
  }
}

// entity XMLAttrValue{
// 	attr : XMLAttr
// 	val  : Text
// 	description : WikiText
// 	siblingAttrVals : List<XMLAttrValue>	
// }
// entity Unit{
//   acronym : String
//   fullName : String
//   regexCheck : String
// }


entity XMLDocInstance{
  base : XMLDocumentBase
  inputs : List<XMLDocInput>
  owner : User (inverse=ownedInstances)
  name  : String
    
  function getXML() : String{
    var fileString := base.uploadedFile.f.getContentAsString();
    var doc := fileString.asXMLDocument();
    for(input in inputs){
      input.applyTo(doc);
    }
    return doc.asString();
  }
  
  function init(){
    for(input in this.inputs){
      input.createInverse();
    }
  }
}

entity XMLDocInput{
  xmlElem : XMLElem
  xmlAttr : XMLAttr
  val     : Text
  
  function applyTo(doc : XMLDocument){
    var xpath := if(xmlElem != null) xmlElem.getXPath() else xmlAttr.getXPath();
    var nodes := doc.getNodesByXPath(xpath);
    if(nodes.length > 0){
      nodes[0].setValue(val as String);
    }
  }
  function createInverse(){
    if(xmlElem != null){
      xmlElem.editInputInternal := this;
    } else {
      xmlAttr.editInputInternal := this;
    }
  }
  extend function setXmlAttr(x : XMLAttr){
    val := x.val;
  }
  extend function setXmlElem(x : XMLElem){
    val := x.val;
  }
}

native class org.w3c.dom.Document as XMLDocument : XMLNode{
  org.webdsl.xml.XMLUtil.getElementsByTagName as getElementsByTagName(String) : List<XMLNode>
  org.webdsl.xml.XMLUtil.getElementsByXPath as getElementsByXPath(String) : List<XMLNode>
  org.webdsl.xml.XMLUtil.getNodesByXPath as getNodesByXPath(String) : List<XMLNode>
  org.webdsl.xml.XMLUtil.asString as asString() : String
}

native class org.w3c.dom.Node as XMLNode{
  org.webdsl.xml.XMLUtil.getElementsByTagName as getElementsByTagName(String) : List<XMLNode>
  org.webdsl.xml.XMLUtil.getElementsByXPath as getElementsByXPath(String) : List<XMLNode>
  javaxt.xml.DOM.getNodeValue as getVal() : String
  org.webdsl.xml.XMLUtil.getText as getVal(String) : String
  javaxt.xml.DOM.getAttributeValue as getAttrVal(String) : String
  org.webdsl.xml.XMLUtil.getChildren as getChildren() : List<XMLNode>
  org.webdsl.xml.XMLUtil.getAttributes as getAttributes() : List<XMLNode>
  getNodeName() : String 
  org.webdsl.xml.XMLUtil.setValue as setValue(String)
}

function deriveScheme(xmlFile : File) : XMLDocumentBase{
    var scheme := XMLDocumentBase{};
    var xmlString := xmlFile.getContentAsString();
    var docNode := xmlString.asXMLDocument() as XMLNode;
    scheme.rootElem := RootXMLElem{};
    log(xmlString);
    scheme.rootElem.deriveMeFrom(docNode, 0);
    return scheme;
}