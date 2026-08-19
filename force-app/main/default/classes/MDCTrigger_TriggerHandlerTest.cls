/*
* @why  : Test class for the MDCTrigger_TriggerHandler.
* @when : 28-DEC-2020.
* @what : Class to handle different scenarios from MDCTrigger_TriggerHandler.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                    Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 28-DEC-2020             TWD Upgrade issue               Created. Added 'executeLogicFromWFRulesTest()' method
*                                                                                   to test moved logic from Workflow Rules with
*                                                                                   Field Updates on MDC Trigger to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class MDCTrigger_TriggerHandlerTest {
    @IsTest
    static void executeLogicFromWFRulesTest() {
        Test.startTest();

        CMPL123__MDC_Trigger__c mdcTrigger =  new CMPL123__MDC_Trigger__c(
            CMPL123__Select_Target_Object__c = 'Complaint__c',
            CMPL123__Criteria__c = 'Created or Changed',
            CMPL123__Logic__c = '1',
            CMPL123__Active__c = true,
            CMPL123__Field__c = 'test'
        );
        insert mdcTrigger;

        mdcTrigger = [SELECT CMPL123__Field__c FROM CMPL123__MDC_Trigger__c];
        
        System.assertEquals(null, mdcTrigger.CMPL123__Field__c);

        mdcTrigger.CMPL123__Field__c = 'test 2';
        update mdcTrigger;

        mdcTrigger = [SELECT CMPL123__Field__c FROM CMPL123__MDC_Trigger__c];
        
        System.assertEquals(null, mdcTrigger.CMPL123__Field__c);

        Test.stopTest();
    }
}