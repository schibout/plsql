LOAD DATA 
REPLACE
INTO TABLE DKA_IEOGLVEC01_LOAD_FLEX_ATTR
fields terminated by ";"
trailing nullcols
(
flex_value          "RTRIM(LTRIM(:flex_value))",
parent              "RTRIM(LTRIM(:parent))",
attribute_value1    "RTRIM(LTRIM(:attribute_value1))",
attribute_value2    "RTRIM(LTRIM(:attribute_value2))",
attribute_value3    "RTRIM(LTRIM(:attribute_value3))",
attribute_value4    "RTRIM(LTRIM(:attribute_value4))",
attribute_value5    "RTRIM(LTRIM(:attribute_value5))",
attribute_value6    "RTRIM(LTRIM(:attribute_value6))",
attribute_value7    "RTRIM(LTRIM(:attribute_value7))",
attribute_value8    "RTRIM(LTRIM(:attribute_value8))",
statut              "'P'"       
 )
