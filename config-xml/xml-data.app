module config-xml/xml-data

entity XMLScheme{
  rootElem : RootXMLElem (inverse=scheme)
}

entity XMLElem{
  tag : String
  description : WikiText
  unit : Unit
  children : List<XMLElem>
  attributes : List<XMLAttr> (inverse=elem)
  parent  : XMLElem (inverse=children)
  childNumber : Int
  xpath : String := getXPath()
  
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
    var attCnt := 0; 
    for(xmlAttr in n.getAttributes()){
    	var attr := XMLAttr{};
      attributes.add(attr);    	
    	attr.deriveMeFrom(xmlAttr, attCnt);
    	attCnt := attCnt + 1;    
    }
    
    var cnt := 0;
    for(child in n.getChildren()){
    	var childElem := XMLElem{};
  		children.add(childElem);
      childElem.deriveMeFrom( child, cnt);
      cnt := cnt + 1;
    }
  }
}

entity RootXMLElem : XMLElem{
  scheme : XMLScheme
  
  function getXPath() : String{ return ""; } 
}

entity XMLAttr{
  elem : XMLElem
  key : String
  val : Text
  description : WikiText
  unit : Unit
  childNumber : Int
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
}

// entity XMLAttrValue{
// 	attr : XMLAttr
// 	val  : Text
// 	description : WikiText
// 	siblingAttrVals : List<XMLAttrValue>	
// }
entity Unit{
  acronym : String
  fullName : String
  regexCheck : String
}


native class org.w3c.dom.Document as XMLDocument : XMLNode{
  org.webdsl.xml.XMLUtil.getElementsByTagName as getElementsByTagName(String) : List<XMLNode>
  org.webdsl.xml.XMLUtil.getElementsByXPath as getElementsByXPath(String) : List<XMLNode>
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
}

function deriveScheme(xmlFile : File) : XMLScheme{
    var scheme := XMLScheme{};
    var xmlString := xmlFile.getContentAsString();
    var docNode := xmlString.asXMLDocument() as XMLNode;
    scheme.rootElem := RootXMLElem{};
    log(xmlString);
    scheme.rootElem.deriveMeFrom(docNode, 0);
    return scheme;
}