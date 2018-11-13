#include "tinyxml/tinyxml.h"
#include "lua_tinker.h"
//#include "windows.h"

extern "C"
{
#include "lua_export.h"
}

int tinyxml_openlibs(lua_State* L)
{
	//--------------------------------TiXmlAttribute--------------------------------
	lua_tinker::class_add<TiXmlAttribute>(L, "TiXmlAttribute");
	lua_tinker::class_def<TiXmlAttribute>(L, "Name", &TiXmlAttribute::Name);
	lua_tinker::class_def<TiXmlAttribute>(L, "Value", &TiXmlAttribute::Value);
	lua_tinker::class_def<TiXmlAttribute>(L, "IntValue", &TiXmlAttribute::IntValue);

	TiXmlAttribute* (TiXmlAttribute::*ptr0)() = &TiXmlAttribute::Next;
	lua_tinker::class_def<TiXmlAttribute>(L, "Next", ptr0);

	//--------------------------------TiXmlElement--------------------------------
	lua_tinker::class_add<TiXmlElement>(L, "TiXmlElement");
	lua_tinker::class_con<TiXmlElement>(L, lua_tinker::constructor<TiXmlElement, const TiXmlElement&>);

	TiXmlElement* (TiXmlElement::*ptr1)(const char *) = &TiXmlElement::FirstChildElement;
	lua_tinker::class_def<TiXmlElement>(L, "FirstChildElement", ptr1);

	TiXmlElement* (TiXmlElement::*ptr2)() = &TiXmlElement::FirstChildElement;
	lua_tinker::class_def<TiXmlElement>(L, "FirstChildElement", ptr2);

	TiXmlElement* (TiXmlElement::*ptr3)() = &TiXmlElement::NextSiblingElement;
	lua_tinker::class_def<TiXmlElement>(L, "NextSiblingElement", ptr3);

	const char* (TiXmlElement::*ptr4)(const char*) const = &TiXmlElement::Attribute;
	lua_tinker::class_def<TiXmlElement>(L, "QueryString", ptr4);

	void (TiXmlElement::*ptr5)(const char*, const char *) = &TiXmlElement::SetAttribute;
	lua_tinker::class_def<TiXmlElement>(L, "SetString", ptr5);

	lua_tinker::class_def<TiXmlElement>(L, "Value", &TiXmlElement::Value);
	lua_tinker::class_def<TiXmlElement>(L, "SetInt", &TiXmlElement::SetDoubleAttribute);
	lua_tinker::class_def<TiXmlElement>(L, "SetDouble", &TiXmlElement::SetDoubleAttribute);
	lua_tinker::class_def<TiXmlElement>(L, "GetText", &TiXmlElement::GetText);

	TiXmlAttribute* (TiXmlElement::*ptr6)() = &TiXmlElement::FirstAttribute;
	lua_tinker::class_def<TiXmlElement>(L, "FirstAttribute", ptr6);

	//--------------------------------TiXMLDocument--------------------------------
	lua_tinker::class_add<TiXmlDocument>(L, "TiXmlDocument");
	lua_tinker::class_con<TiXmlDocument>(L, lua_tinker::constructor<TiXmlDocument>);

	bool (TiXmlDocument::*ptr7)(const char*, TiXmlEncoding) = &TiXmlDocument::LoadFile;
	lua_tinker::class_def<TiXmlDocument>(L, "LoadFile", ptr7);

	TiXmlElement* (TiXmlDocument::*ptr8)() = &TiXmlDocument::RootElement;
	lua_tinker::class_def<TiXmlDocument>(L, "RootElement", ptr8);

	//MessageBoxA(NULL, "tinyxml", "", 0);

	return 1;
}
