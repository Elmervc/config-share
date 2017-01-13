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
  
  function deriveMeFrom(n : XMLNode){
    tag := n.getNodeName();
    var keys :=[a.key | a : XMLAttr in attributes];
    
    var thisElemAttributes := List<XMLAttr>();
    	 
    for(xmlAttr in n.getAttributes()){
    	var attr : XMLAttr;
    	var idx := keys.indexOf( xmlAttr.getNodeName() );
    	if( idx < 0 ){
    		attr := XMLAttr{};
    		keys.add(xmlAttr.getNodeName());
        attributes.add(attr);
    	} else {
    		attr := attributes[idx];
    	}
    	
    	attr.deriveMeFrom(xmlAttr);
    	thisElemAttributes.add(attr);      
    }
    //keep track of attributes that belong together, e.g. in <parameter name="paramname" value="paramvalue">, map kv-pair name="paramname" to one or more kv-pairs value="paramvalue". 
    var siblingAttrValues := [a.instanceValue | a : XMLAttr in thisElemAttributes];
    for(siblingAttrVal in siblingAttrValues){
    	siblingAttrVal.siblingAttrVals.addAll(siblingAttrValues);
    	siblingAttrVal.siblingAttrVals.remove( siblingAttrVal );
    }    
    
    var childTags := [c.tag | c: XMLElem in children];
    
    for(child in n.getChildren()){
    	var childElem : XMLElem;
    	var idx := childTags.indexOf( child.getNodeName() );
    	if( idx < 0 ){
    		childElem := XMLElem{};
    		children.add(childElem);
    	  childTags.add( child.getNodeName() );
    	} else {
    		childElem := children[idx];
    	}      
      childElem.deriveMeFrom( child );
    }
  }
}

entity RootXMLElem : XMLElem{
  scheme : XMLScheme
}

entity XMLAttr{
  elem : XMLElem
  key : String
  description : WikiText
  unit : Unit
  attrValues : List<XMLAttrValue> (inverse=attr)
  instanceValue : XMLAttrValue (transient)
  
  function deriveMeFrom(n : XMLNode){
    key := n.getNodeName();
    
    var attrValuesString := [av.val | av : XMLAttrValue in attrValues];
    var idx := attrValuesString.indexOf( n.getVal() );
    if(idx < 0){
    	instanceValue := XMLAttrValue{
    		attr := this
    		val  := n.getVal()
    	};
    	attrValuesString.add( instanceValue.val );
    } else {
    	instanceValue := attrValues[idx];
    }
    
  }
}

entity XMLAttrValue{
	attr : XMLAttr
	val  : Text
	description : WikiText
	siblingAttrVals : List<XMLAttrValue>	
}
entity Unit{
  acronym : String
  fullName : String
  regexCheck : String
}


// section XML
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
  getBaseURI() : String
  
}

function deriveScheme(xmlFile : File) : XMLScheme{
    var scheme := XMLScheme{};
    var xmlString := xmlFile.getContentAsString();
    var docNode := xmlString.asXMLDocument() as XMLNode;
    scheme.rootElem := RootXMLElem{};
    log(xmlString);
    scheme.rootElem.deriveMeFrom(docNode);
    return scheme;
}