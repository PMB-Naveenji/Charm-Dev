/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : GetFieldLabelAPITest.
* @Why   : GetFieldLabelAPITest test class for the GetFieldLabelAPI class.
* @When  : 13-AUG-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 13-AUG-2020         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class GetFieldLabelAPITest {

    /*
    * @Method       : requiredFieldsFromsObjectTest.
    * @Description  : To test the GetFieldLabelAPI functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest static void requiredFieldsFromsObjectTest() {

        Test.startTest();
        GetFieldLabelAPI.requiredFieldsFromsObject();
        Test.stopTest();
        
        System.assertEquals(1, [SELECT COUNT() FROM Document], 'Document should be created');
    }
}