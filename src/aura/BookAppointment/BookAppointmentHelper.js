({
    getAllAppointments : function(component,event,helper)
    {
      	var action = component.get('c.getAppointments') ;
        action.setParams({contactId : component.get('v.recordId')}) ;
        action.setCallback(component,function(response)
        {
            var state = response.getState() ;
            if(state == 'SUCCESS')
            {
                var records = response.getReturnValue() ;
                var cal_events = [] ;
                if(records != null)
                {
                    if(records.length > 0)
                    {
                        for(var i = 0 ; i < records.length ; i ++)
                        {   
                            var cal_event = new Object() ;
                            cal_event.title = records[i].objAppointment.Name ;
                            cal_event.subject = records[i].objAppointment.Subject__c ;
                            cal_event.appointmentDate = records[i].objAppointment.Appointment_Date__c ;
                            cal_event.startTime = records[i].objAppointment.Start_Time__c ;
                            cal_event.endTime = records[i].objAppointment.End_Time__c ;
                            cal_event.start = records[i].StartDateTime ;
                            cal_event.end = records[i].EndDateTime ;
                            cal_event.backgroundColor = '#008000' ;
                            cal_event.borderColor = '#008000' ;
                            cal_event.textColor = '#ffffff' ;
                            cal_events.push(cal_event) ;
                        }
                    }
                }
                component.set('v.Appointments',cal_events) ;
                component.displayAppointmentsInCalendar() ;
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                var errorMessage ;
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        errorMessage = "Error message: " + errors[0].message ;
                        console.log(errorMessage);
                        
                    }
                } else {
                    errorMessage = 'Unknown error.Please Contact your System Admin.'
                    console.log("errorMessage");
                }
            }               
        }) ;
        $A.enqueueAction(action) ;
    },
    getDayClickEvent : function(component,event,helper,date)
   	{
        component.set('v.isError',false) ;
        var startTime ;
        var endTime ;
        var constructDate = new Date(date) ;
        var allAppointments = component.get('v.Appointments') ;
        var time_options = component.get('v.TimeOptions') ;
        for(var i = 0 ; i < time_options.length ; i ++)
        {
            time_options[i].isDisabled = false ;
        }
        
        if(allAppointments.length > 0 )
        {
            for(var i = 0 ; i < allAppointments.length ; i++)
            {
                if(allAppointments[i].appointmentDate == moment(constructDate).format('YYYY-MM-DD'))
                {
                    for(var j = 0 ; j < time_options.length ; j ++)
                    {
                        if(time_options[j].value >= allAppointments[i].startTime && time_options[j].value < allAppointments[i].endTime)
                        {    
                            time_options[j].isDisabled = true ;
                        }
                    }
                }
            }
        }
        
        var isTimeSlotAvailable = true ;
        for(var i = 0 ; i < time_options.length ; i++)
        {
            if(time_options[i].isDisabled == false)
            {
                isTimeSlotAvailable = false ;
                startTime = time_options[i].value ;
                endTime = time_options[i].value ;
                break ;
            }
        }
        
        if(isTimeSlotAvailable == true)
        {
            component.set('v.isError',true) ;
            component.set('v.errMsg','Error:No available time slots for '+date) ;
        }
        
        component.set('v.TimeOptions',time_options) ;
        var newCalendarEvent = new Object() ;
        newCalendarEvent.Subject = '' ;
        newCalendarEvent.AppointmentDate = moment(constructDate).format('MM/DD/YYYY') ;
        newCalendarEvent.StartTime = startTime ;
        newCalendarEvent.EndTime = endTime ;
        component.set('v.Appointment',newCalendarEvent) ;
        this.openModal(component,event,helper) ;
   	},
    closeModal : function(component, event, helper) {
        component.set("v.isOpen", false);
    },
    openModal : function(component, event, helper) {
        component.set("v.isOpen", true);
    },
    showToast : function(component, event,t_title,t_message,t_messageTemplate,t_type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : t_title,
            message: t_message,
            messageTemplate: t_messageTemplate,
            duration:'5000',
            key: 'info_alt',
            type: t_type,
            mode: 'dismissible'
        });
        toastEvent.fire();
    },
})