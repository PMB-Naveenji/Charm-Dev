/* 
* @why  : ADDReopenJustificationTriggerHandlerTest class for Re_Open_Justification_AuditTrigger
* @when : CreatedDate : 26-SEPTEMBER-2018    
* @what : Class to Handle Different scenarios from Re_Open_Justification_AuditTrigger
* Modification Log:  
* --------------------------------------------------------------------------------------------------------------------------------------
*  Developer                Date                   Modification ID      Description 
* --------------------------------------------------------------------------------------------------------------------------------------
*  oivan                    05-JAN-2021            TWD Upgrade issue    Added testWFLogic() for testing disabled WF logic
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class ADDReopenJustificationTriggerHandlerTest {
    
                        /**
* @Method       :  
* @Description  :   To test the Re_Open_Justification_AuditTrigger functionality.
* @Return       : N/A
* @Params       : N/A
**/
    @isTest
    public static void testADDReopenJustificationTriggerHandler(){
        
        // Create Application Setup data
        Re_Open_Justification__c reopenJustificationRecord = (Re_Open_Justification__c) TestDataFactory.createSObject(new Re_Open_Justification__c(), true);
        Update reopenJustificationRecord;
        Delete reopenJustificationRecord; 
        System.assertEquals(new List<Re_Open_Justification__c>(), [SELECT Id FROM Re_Open_Justification__c]);
    }
	
	/**
	* @Method       : testWFLogic
	* @Description  : TWD Upgrade issue. Test WF logic that was moved to apex.
	* @Return       : N/A
	* @Params       : N/A
	**/    
    static testmethod void testWFLogic(){
		Re_Open_Justification__c reopenJustificationRecord = (Re_Open_Justification__c) TestDataFactory.createSObject(new Re_Open_Justification__c(Ticket_Re_Open_Rationale_Native__c = 'Test123'), true);
		System.assertEquals('Test123', [SELECT Re_Open_Justification_Added__c FROM Re_Open_Justification__c WHERE id =: reopenJustificationRecord.Id].Re_Open_Justification_Added__c);
		
	}
}