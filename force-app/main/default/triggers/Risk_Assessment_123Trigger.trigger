/********************************************************************************************************************
	Copyright (c) 2017 Sparta Systems, Inc.

	THIS IS AN AUTO-GENERATED TRIGGER CREATED BY  TRACKWISE DIGITAL PLATFORM PACKAGE
	Note: Follow the guidelines on how to use/implement 123 Triggers
	Add your custom code before  X123TriggerHandler. X123TriggerHandler code should be on the last line.
*********************************************************************************************************************/
/* 
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID                        Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                    15-MAY-2020            CHARM-2586 (Migrated process issue)    Added condition to skip code for Data Loader User
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit                             Removed commented code. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*/
trigger Risk_Assessment_123Trigger on Risk_Assessment__c (before insert,after insert,before update,after update,before delete,after delete,after undelete){
	
	//Condition added for CHARM-2586 to skip the code for Data Loader User
    if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
		
		CMPL123.X123TriggerHandler X123handler = new CMPL123.X123TriggerHandler();

		/* Before Insert */
		if(Trigger.isInsert && Trigger.isBefore){
			// Place your custom code here 
			X123handler.handleBeforeInsert();
		}

		/* After Insert */
		else if(Trigger.isInsert && Trigger.isAfter){
			// Place your custom code here 
			X123handler.handleAfterInsert();
			ReportsRelatedDataUtil.updatePMRAWithRiskAssessmentsData(Trigger.old, Trigger.new);
		}

		/* Before Update */
		else if(Trigger.isUpdate && Trigger.isBefore){
			// Place your custom code here 
			X123handler.handleBeforeUpdate();
		}

		/* After Update */
		else if(Trigger.isUpdate && Trigger.isAfter){
			// Place your custom code here 
			X123handler.handleAfterUpdate();
			ReportsRelatedDataUtil.updatePMRAWithRiskAssessmentsData(Trigger.old, Trigger.new);
		}

		/* Before Delete */
		else if(Trigger.isDelete && Trigger.isBefore){
			X123handler.handleBeforeDelete();
		}

		/* After Delete */
		else if(Trigger.isDelete && Trigger.isAfter){
			// Place your custom code here 
			X123handler.handleAfterDelete();
			ReportsRelatedDataUtil.updatePMRAWithRiskAssessmentsData(Trigger.old, Trigger.new);
		}

		/* After UnDelete */
		else if(Trigger.isUnDelete && Trigger.isAfter){
			// Place your custom code here 
			X123handler.handleAfterUnDelete();
		}
	}
}