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
    *   Developer                Date                   Modification ID                                                Description 
    *  --------------------------------------------------------------------------------------------------------------------------------------
    *      oivan                15-APR-2020             CHARM-2400 (67 - General - Critical /Audit Trail Pick List)     AutoCreated.
    *  --------------------------------------------------------------------------------------------------------------------------------------
    *      oivan                15-MAY-2020             CHARM-2586 (Migrated process issue)                            Modified. 
    *                                                                                        Added condition to skip code for Data Loader User
    *  --------------------------------------------------------------------------------------------------------------------------------------
*/
trigger CMPL123CME_MDR_Code_123Trigger on CMPL123CME__MDR_Code__c (before insert,after insert,before update,after update,before delete,after delete,after undelete){
	
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
		}

		/* Before Delete */
		else if(Trigger.isDelete && Trigger.isBefore){
			// Place your custom code here 
			X123handler.handleBeforeDelete();
		}

		/* After Delete */
		else if(Trigger.isDelete && Trigger.isAfter){
			// Place your custom code here 
			X123handler.handleAfterDelete();
		}

		/* After UnDelete */
		else if(Trigger.isUnDelete && Trigger.isAfter){
			// Place your custom code here 
			X123handler.handleAfterUnDelete();
		}
	}
}