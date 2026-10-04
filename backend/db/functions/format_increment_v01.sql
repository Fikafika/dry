CREATE OR REPLACE FUNCTION format_increment (sequence_name varchar, format1 integer, type1 integer, format2 integer, type2 integer,
format3 integer, type3 integer)  RETURNS varchar as $$
-- format the increment into the requested format
-- type1, type2, type3  : if 0 -> integer format, if 1 -> characters format
DECLARE
  value bigint;
  quotient1 bigint;
  rest1 bigint;
  quotient2 bigint;
  rest2 bigint;
BEGIN
  value := nextval(sequence_name);
  IF format3>0 THEN
    IF type3=0 THEN
      rest1 := value%(CAST(10^(format3) AS integer));
      quotient1 := CAST(trunc(value/(10^format3)) AS bigint);
      rest2 := CAST(quotient1%(CAST((26^format2) AS integer)) AS bigint);
      quotient2 := CAST(trunc(quotient1/(26^format2)) AS bigint);
      RETURN CONCAT(to_char(quotient2, compute_format(format1)), formatted_base_26(rest2, format2), to_char(rest1, compute_format(format3)));
    ELSE
      rest1 := CAST(value%(CAST((26^format3) AS integer)) AS bigint);
      quotient1 := CAST(trunc(value/(26^format3)) AS bigint);
      rest2 := quotient1%(CAST(10^format2 AS integer));
      quotient2 := CAST(trunc(quotient1/(10^format2)) AS bigint);
      RETURN CONCAT(formatted_base_26(quotient2, format1), to_char(rest2, compute_format(format2)), formatted_base_26(rest1, format3));
    END IF;
  ELSIF format2>0 THEN
    IF type2=0 THEN
      rest1 := value%(CAST(10^format2 AS integer));
      quotient1 := CAST(trunc(value/(10^format2)) AS bigint);
      RETURN CONCAT(formatted_base_26(quotient1, format1), to_char(rest1, compute_format(format2)));
    ELSE
      rest1 := CAST(value%(CAST((26^format2) AS integer)) AS bigint);
      quotient1 := CAST(trunc(value/(26^format2)) AS bigint);
      RETURN CONCAT(to_char(quotient1, compute_format(format1)), formatted_base_26(rest1, format2));
    END IF;
  ELSIF type1=0 THEN
    RETURN to_char(value, compute_format(format1));
  ELSE
    RETURN formatted_base_26(value, format1);
  END IF;
END
$$ LANGUAGE plpgsql;
