/*
* @why  : Test class for the MDCAckMappingTriggerHandler.
* @when : 28-DEC-2020.
* @what : Class to handle different scenarios from MDCAckMappingTriggerHandler.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                    Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 28-DEC-2020             TWD Upgrade issue               Created. Added 'executeLogicFromWFRulesTest()' method
*                                                                                   to test moved logic from Workflow Rules with
*                                                                                   Field Updates on MDCAcknowledgementMapping to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class MDCAckMappingTriggerHandlerTest {
    @IsTest
    static void executeLogicFromWFRulesTest() {
        Test.startTest();

        CMPL123__MDC_Trigger__c mdcTrigger = new CMPL123__MDC_Trigger__c(
            CMPL123__Select_Target_Object__c = 'Complaint__c',
            CMPL123__Criteria__c = 'Created or Changed',
            CMPL123__Logic__c = '1',
            CMPL123__Active__c = true
        );
        insert mdcTrigger;

        CMPL123__AcknowledgementMapping__c ackMapping = new CMPL123__AcknowledgementMapping__c(
            CMPL123__MDC_Trigger_Acknowledgment__c = mdcTrigger.Id,
            CMPL123__PublicGroupAcknowledgment__c = 'Evaluator/Investigator'
        );
        insert ackMapping;

        System.assertEquals(
            ackMapping.CMPL123__PublicGroupAcknowledgment__c,
            [SELECT Selected_Group_Name__c FROM CMPL123__MDC_Trigger__c LIMIT 1].Selected_Group_Name__c
        );

        Test.stopTest();
    }
}