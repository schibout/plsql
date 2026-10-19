LOAD DATA 
REPLACE
INTO TABLE dka_ieoglvec01_load_flex_value
fields terminated by ";"
trailing nullcols
(
   flex_value	"RTRIM(LTRIM(:flex_value))",
   description	        ,
   language     "RTRIM(LTRIM(:language))",
   statut  "'P'"
 )
