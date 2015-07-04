using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Attention as Att;

class AscentDataFieldView extends Ui.SimpleDataField {

	var lastAltitudes=new [MaxN];
	var lastPositions=new [MaxN];
	var lastTimes = new [MaxN];
	var Npoints;
	var MaxN=10;					//number of points in the buffer arrays
	var lastPos;
	var slopeThreshold = 0.03;		//minimum slope to be considered an ascent
	var stopThreshold = 10;			//descent (m) that triggers the end of the ascent
	
	var lastAscentStatus;			//1: if going up, 0 otherwise
	var ascentActive; 				//if the user is going up or not yet down enough to stop the ascent
	
	var ascentElevationEnd;			//last detected elevation while ascent status==1
	var ascentTimerEnd;				//last detected time while ascent status ==1 
	
	var ascentElevationStart;		//first detected elevation while ascent status = 1
	var ascentTimerStart;			//first detected time while ascent status =1
	
	
	var lastVal;
	
    //! Set the label of the data field here.
    function initialize() {
        label = "Last Ascent";
        Npoints = 0;
        lastAltitudes=new [MaxN];
        lastPositions=new [MaxN];
        lastTimes = new [MaxN];
        
        lastPos=0;
        lastVal=0;
        
        lastAscentStatus = 0;
        ascentElevationStart = 0;
        ascentTimerStart = 0;
        ascentActive = false;
    }

    //! The given info object contains all the current workout
    //! information. Calculate a value and return it in this method. 
    function compute(info) {
        // See Activity.Info in the documentation for available information.
		var alt = info.altitude;
		var pos = info.elapsedDistance;
		var time = info.timerTime;
		
		if(pos==null)
		{
			return null;
		}
		
		if(alt!=null && (pos-lastPos)>0.1)
		{
			lastPos = pos;	
		    
		    if(Npoints<MaxN)
    		{
	    		//filling the array during the activity startup
	      		lastAltitudes[Npoints]=alt;
	      		lastPositions[Npoints]=pos;
	      		lastTimes[Npoints] = time;
	      		Npoints = Npoints+1;
	      		return "WAIT..."+0;
    		}
    		
    		//first we store the new data		
    		UpdateArrays(alt, pos, time);
	    	
		    //===========================================
		    //after the arrays are ready we can check
		
		    var newStatus = AscentStatus();
		    //check if we are going up
		    if(newStatus==0)
		    {
				//not going up (enough)
				if(ascentActive)
				{
					//if the ascent is still active, we check whether to keep it active
					if(ascentElevationEnd-alt>stopThreshold)
					{
						//the ascent is really over!
						ascentActive=false;
					}
					
					//keep displaying the value calculated when it was going up
					lastVal = "(" + ascentElevationEnd-ascentElevationStart + ")" ;
				}
				else
				{
					//if the ascent is not active any more we display the descent
					lastVal = alt - ascentElevationEnd;
				}
				
				
		    }
		    else
		    {
			  	//going up
				
			    if(ascentActive==false)
		        {
			         //first detection
			         //Att.playTone(TONE_DISTANCE_ALERT);
			         ascentElevationStart = lastAltitudes[0];
			         ascentTimerStart = lastTimes[0];
			         lastAscentStatus = 1;
			         ascentActive = true;
		        } 
		        
		        ascentElevationEnd = alt;
		        
		        //computing the average speed so far
		        //var speed=(ascentElevationEnd-ascentElevationStart)/(time-ascentTimerStart+0.01)/(3600.0*1000.0);
		        lastVal= alt-ascentElevationStart;
		   	}
		}
	
		return lastVal;
		
    }
    
    function UpdateArrays(alt,pos,time)
    {
	    //updates the arrays with the FIFO logic
		for(var i=0; i<MaxN-1; i++)						//up to MaxN-1 !
		{
			lastAltitudes[i]=lastAltitudes[i+1];
			lastPositions[i]=lastPositions[i+1];
			lastTimes[i]=lastTimes[i+1];
		}
		  
		//new value in
		lastAltitudes[MaxN-1]=alt;
		lastPositions[MaxN-1]=pos;
		lastTimes[MaxN-1]=time;
				      
    }
    
    
    
    //returns 1 if currently going up (slope>threshold), 0 otherwise
    function AscentStatus() 
    {
    	//calculate the slope, todo: changing with the linear fit
		var ds = lastPositions[MaxN-1]-lastPositions[0];
		if(ds<0.01)
		{
			ds=0.01;
		}
		
		var slope=(lastAltitudes[MaxN-1]-lastAltitudes[0])/ds;
		
		if(slope>slopeThreshold)
		{
			return 1;
		}
		return 0;
    }

}