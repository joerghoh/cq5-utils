package de.joerghoh.cq5.utils.maintenance;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.felix.scr.annotations.Activate;
import org.apache.felix.scr.annotations.Component;
import org.apache.felix.scr.annotations.Properties;
import org.apache.felix.scr.annotations.Property;
import org.apache.felix.scr.annotations.Service;
import org.osgi.service.component.ComponentContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.apache.sling.commons.osgi.PropertiesUtil;

@Component(immediate=true,metatype=true, label="CQ5 Utils Maintenance Filter", description="Enables a simple maintenance mode to block certain users")
@Service(value=Filter.class)
@Properties({
	@Property(name="service.description", value="CQ5 Utils Maintenance Filter", propertyPrivate=true),
	@Property(name="service.name", value="CQ5 Utils Maintenance Filter 2", propertyPrivate=true)
})
public class MaintenanceFilter implements Filter {
	
	private Logger log = LoggerFactory.getLogger(this.getClass());

	@Property(boolValue=false, description="Check this to enable the maintenance mode", label="Enable maintenance mode")
	private static String MAINTENANCE_ENABLED="maintenance.enabled";
	private boolean maintenanceEnabled = false;
	
	@Property(value={"admin"}, description="Users which are allowed to access the system in maintenance mode", label="Allowed users", cardinality=Integer.MAX_VALUE)
	private static final String ALLOWED_USERS="allowedUsers";
	private String[] allowedUsers = {"admin"};
	
	@Property(boolValue=false, description="Block anonymous (unauthenticated) requests", label="Block anonymous")
	private static final String BLOCK_ANONYMOUS="blockAnonymous";
	private boolean blockAnonymous=false;


	/**
	 *  The filter: Forward the request only through the filter chain, if
	 *  the maintenance mode is not enabled..
	 */
	public void doFilter(ServletRequest request, ServletResponse response,
			FilterChain chain) throws IOException, ServletException {
		
		boolean canForward=true;
		if (maintenanceEnabled) {
			canForward = checkRequest(request);
		}
		
		
		if (canForward) {
			chain.doFilter(request, response);
		} else {
			if (response instanceof HttpServletResponse) {
				HttpServletResponse resp = (HttpServletResponse) response;
				HttpServletRequest req = (HttpServletRequest) request;
				log.debug("blocked request for {} because of maintenance",req.getUserPrincipal().getName());
				resp.sendError(503,"Maintenance active");
				
			}
		}

		
	}

	public void init(FilterConfig arg0) throws ServletException {
		// TODO Auto-generated method stub
		
	}
	
	public void destroy() {
		// do nothing
		
	}

	@Activate
	protected void activate (ComponentContext context) {
		maintenanceEnabled = PropertiesUtil.toBoolean(context.getProperties().get(MAINTENANCE_ENABLED),false);
		allowedUsers = PropertiesUtil.toStringArray(context.getProperties().get(ALLOWED_USERS),allowedUsers);
		blockAnonymous = PropertiesUtil.toBoolean(context.getProperties().get(BLOCK_ANONYMOUS),blockAnonymous);

	}

	private boolean checkRequest (ServletRequest request) {
		if (!(request instanceof HttpServletRequest)) {
			log.error("Not received an HTTPServletRequest!");
			return false;
		}
		HttpServletRequest r = (HttpServletRequest) request;
		String user = r.getUserPrincipal().getName();

		if (user == null) {
			// ok, something must be wrong
			log.warn("user is null!");
			return false;
		}

		if (!user.equals("anonymous")) {
			// user is authenticated
			for (String u: allowedUsers) {
				if (user.equals(u)) {
					return true;
				}
			}
			return false; // user is not whitelisted 
		} 
		// allow anonymous access if not blocked explicitly
		if (user.equals("anonymous") && !this.blockAnonymous) {
			return true;
		}
			
		// fallback, should never be reached
		return false;
	}
	
	
}
