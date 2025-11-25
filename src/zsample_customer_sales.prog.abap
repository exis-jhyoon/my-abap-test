REPORT zsample_customer_sales.

*-------------------------------------------------------------*
* 타입 정의
*-------------------------------------------------------------*
TYPES: BEGIN OF ty_sales,
         customer_id TYPE char10,
         product_id  TYPE char10,
         sales_date  TYPE d,
         quantity    TYPE i,
         unit_price  TYPE p DECIMALS 2,
       END OF ty_sales.

TYPES: BEGIN OF ty_customer_summary,
         customer_id TYPE char10,
         total_sales TYPE p DECIMALS 2,
       END OF ty_customer_summary.

*-------------------------------------------------------------*
* 내부 테이블 선언
*-------------------------------------------------------------*
DATA: lt_sales_data     TYPE TABLE OF ty_sales,
      lt_summary        TYPE TABLE OF ty_customer_summary,
      ls_summary        TYPE ty_customer_summary,
      lv_total_all      TYPE p DECIMALS 2,
      lv_avg_sales      TYPE p DECIMALS 2.

*-------------------------------------------------------------*
* 샘플 데이터 생성
*-------------------------------------------------------------*
DO 50 TIMES.
  DATA(ls_sales) = VALUE ty_sales(
    customer_id = |CUST{ sy-index MOD 10 }|
    product_id  = |PROD{ sy-index MOD 5 }|
    sales_date  = sy-datum - ( sy-index MOD 40 )
    quantity    = ( sy-index MOD 7 ) + 1
    unit_price  = ( sy-index MOD 20 ) + 10 ).
  APPEND ls_sales TO lt_sales_data.
ENDDO.

*-------------------------------------------------------------*
* 최근 30일 데이터 필터링
*-------------------------------------------------------------*
DELETE lt_sales_data WHERE sales_date < sy-datum - 30.

*-------------------------------------------------------------*
* 고객별 매출 합계 계산
*-------------------------------------------------------------*
LOOP AT lt_sales_data INTO DATA(ls_data).
  READ TABLE lt_summary INTO ls_summary
       WITH KEY customer_id = ls_data-customer_id.
  IF sy-subrc = 0.
    ls_summary-total_sales = ls_summary-total_sales +
                             ( ls_data-quantity * ls_data-unit_price ).
    MODIFY lt_summary FROM ls_summary INDEX sy-tabix.
  ELSE.
    ls_summary = VALUE ty_customer_summary(
                   customer_id = ls_data-customer_id
                   total_sales = ls_data-quantity * ls_data-unit_price ).
    APPEND ls_summary TO lt_summary.
  ENDIF.
ENDLOOP.

*-------------------------------------------------------------*
* 전체 평균 매출 계산
*-------------------------------------------------------------*
LOOP AT lt_summary INTO ls_summary.
  lv_total_all = lv_total_all + ls_summary-total_sales.
ENDLOOP.

lv_avg_sales = lv_total_all / lines( lt_summary ).

*-------------------------------------------------------------*
* 상위 5 고객 출력
*-------------------------------------------------------------*
SORT lt_summary BY total_sales DESCENDING.

WRITE: / 'Top 5 Customers (최근 30일)', / '=============================='.

LOOP AT lt_summary INTO ls_summary FROM 1 TO 5.
  WRITE: / 'Customer:', ls_summary-customer_id,
         'Total Sales:', ls_summary-total_sales.
  IF ls_summary-total_sales >= lv_avg_sales.
    WRITE: ' -> 우수 고객'.
  ENDIF.
ENDLOOP.

WRITE: / '==============================',
         / '전체 평균 매출액:', lv_avg_sales.
