
update fnd_flex_values ffv
set attribute18 = 'N',
    value_category = 'DAOPCCF_LOCAL'
 WHERE ffv.flex_value_set_id IN
       (SELECT flex_value_set_id
          FROM fnd_flex_value_sets ffvs
         WHERE flex_value_set_name = 'DAOPCCF_LOCAL')
         AND attribute18 is null;
commit;
EXIT;