package de.joerghoh.cq5.utils.slowrequests;
/*
 * Copyright 2013 Jšrg Hoh
 * 
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
import java.io.IOException;
import java.util.Enumeration;
import java.util.Iterator;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;

import org.apache.felix.scr.annotations.Component;
import org.apache.felix.scr.annotations.Properties;
import org.apache.felix.scr.annotations.Property;
import org.apache.felix.scr.annotations.Service;
import org.apache.sling.api.SlingHttpServletRequest;
import org.apache.sling.commons.osgi.PropertiesUtil;
import org.osgi.service.component.ComponentContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * 
 * @author Jšrg Hoh (joerg@joerghoh.de)
 * 
 * This servlet filter logs requests which exceed a defined time to get rendered.
 * From such a request these information are logged:
 *  * all HTTP headers
 *  * the request body in case of a POST request
 *  * the content of the RequestProgressTracker
 *  
 *  It is supposed to provide enough information to track slow requests after
 *  they happend.
 *  
 *  You should create a dedicated logfile for this class, so your error.log
 *  isn't polluted with these logs.
 *
 */
@Component(immediate=true, metatype=true, label="Slow Requests Filter")
@Service(value=Filter.class)
@Properties({ @Property(name = "sling.filter.scope", value = "request", propertyPrivate=true) })
public class SlowRequestFilter implements Filter {
	
	private Logger log = LoggerFactory.getLogger(this.getClass());
	
	@Property(boolValue=false)
	private static final String FILTER_ENABLED="slowRequests.enabled";
	private boolean enabled = false;
	
	@Property(intValue=5000)
	private static final String TIME_LIMIT="slowRequests.timeLimit";
	private static final int DEFAULT_TIME_LIMIT=5000;
	private int timeLimit = DEFAULT_TIME_LIMIT;


	/**
	 * do the filtering only if the it's enabled. Avoid any overhead in that case.
	 */
	public void doFilter(ServletRequest request, ServletResponse response,
			FilterChain chain) throws IOException, ServletException {
		
		if (enabled) {
			long t1 = System.currentTimeMillis();
			chain.doFilter(request, response);
			long t2 = System.currentTimeMillis();
			long duration = t2 - t1;
			
			if (duration > timeLimit) {
				SlingHttpServletRequest r = (SlingHttpServletRequest) request;
				logRequest (r, duration);
			}
			
		} else {
			chain.doFilter(request,response);
		}
		
	}

	public void init(FilterConfig arg0) throws ServletException {
		// TODO Auto-generated method stub
		
	}
	
	public void destroy() {
		// TODO Auto-generated method stub
		
	}
	
	@org.apache.felix.scr.annotations.Activate
	protected void Activate (ComponentContext ctx) {
		enabled = PropertiesUtil.toBoolean(ctx.getProperties().get(FILTER_ENABLED), false);
		timeLimit = PropertiesUtil.toInteger(TIME_LIMIT, DEFAULT_TIME_LIMIT);
		if (enabled) {
			log.info("Logs requests slower than {} miliseconds", timeLimit);
		}
	}

	/**
	 * Log all relevant information from the request
	 * @param request
	 * @param duration
	 */
	private void logRequest (SlingHttpServletRequest request, long duration) {
		StringBuffer msg = new StringBuffer ("Logging slow statement:\n");
		msg.append("Duration=").append(duration).append("ms\n");
		msg.append("HTTP header\n\t")
			.append(request.getMethod())
			.append(" ").append(request.getRequestURI())
			.append(" ").append(request.getProtocol())
			.append("\n");
		Enumeration<String> headers = request.getHeaderNames();
		while (headers.hasMoreElements()) {
			String h = headers.nextElement();
			msg.append("\t").append(h).append(" = ").append(request.getHeader(h)).append("\n");
		}
		
		// add the body of the request if it's a POST request
		if ("POST".equals(request.getMethod().toUpperCase())) {
			msg.append("Body of POST request\n");
			Enumeration<String> bodyparams = request.getParameterNames();
			while (bodyparams.hasMoreElements()) {
				String key = bodyparams.nextElement();
				String value = request.getParameter(key);
				if (value.length() > 100) {
					value = value.substring(0, 100) + " ... (" + value.length() + " characters)";
				}
				msg.append("\t")
					.append(key)
					.append(" = ")
					.append(value)
					.append("\n");
			}
		}
		
		msg.append("RequestProgressTracker:\n");
		Iterator<String> rm = request.getRequestProgressTracker().getMessages();
		while (rm.hasNext()) {
			msg.append("\t").append(rm.next());
		}
		msg.append("\n");
		log.info(msg.toString());
	}
	
}
