/*
* @why  : Test class for the ADDCustomerResponseMasterHandler.
* @when : 27-MAY-2019.
* @what : Class to handle different scenarios from ADDCustomerResponseMasterHandler.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                    Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                 27-MAY-2019             Code Audit                      Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 28-DEC-2020             TWD Upgrade issue               Added 'executeLogicFromWFRulesTest()' method to test moved
*                                                                                   logic from Workflow Rules with Field Updates on CRM to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class ADDCustomerResponseMasterHandlerTest {
    @IsTest
    public static void testCustomerResponseMasterHandler () {
        Customer_Response_Master__c crm = new Customer_Response_Master__c ();
        insert crm;

        crm.Category__c = 'Stability';
        crm.CMPL123_WF_Status__c = 'Closed-Done';

        try {
            update crm;
        } catch (System.DmlException e) {
            System.assertEquals(true, e.getMessage().contains('Update failed'));
        }

        crm.CMPL123_WF_Status__c = '';
        update crm;

        crm = [SELECT Id, Category__c, Category_Text_Hidden__c FROM Customer_Response_Master__c WHERE Id = :crm.Id][0];

        System.assertEquals(crm.Category__c, crm.Category_Text_Hidden__c);

        delete crm;

        System.assertEquals(0, [SELECT COUNT() FROM Customer_Response_Master__c WHERE Id = :crm.Id]);
    }

    @IsTest
    static void executeLogicFromWFRulesTest() {
        String actionPerformedBy = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

        Test.startTest();

        Customer_Response_Master__c crm = new Customer_Response_Master__c(
            CMPL123_WF_Status__c = 'Closed-Done',
            CMPL123_WF_Action__c = 'Approve',
            CMPL123Rule_Key_Value__c = 'CUSTOMER_RESPONSE_MASTER_WORKFLOW'
        );

        insert crm;

        Customer_Response_Master__c newCRM = [SELECT Id, Customer_Letter_Approved_By__c
                                                FROM Customer_Response_Master__c
                                                WHERE Id = :crm.Id];

        System.assertEquals(actionPerformedBy, newCRM.Customer_Letter_Approved_By__c);

        Customer_Response_Master__c crm2 = new Customer_Response_Master__c(
            CMPL123_WF_Status__c = 'Closed-Retired',
            CMPL123_WF_Action__c = 'Retire',
            CMPL123Rule_Key_Value__c = 'CUSTOMER_RESPONSE_MASTER_WORKFLOW'
        );

        insert crm2;

        newCRM = [SELECT Id, Retired_By__c FROM Customer_Response_Master__c WHERE Id = :crm2.Id];

        System.assertEquals(actionPerformedBy, newCRM.Retired_By__c);

        Test.stopTest();
    }
}