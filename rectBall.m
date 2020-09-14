%{
a preview for deletes could be useful

can pass through very thin rects.

speed boost rects? (and slow downs)
-maybe tapping a rect or something changes its function

will pass out of rect drawn over it, but can still bounce on overlapping
rects and be hidden forever
- I either fixed this by accident or forgot how to trigger it.

make brick breaker. same code really, just delete a rect after hitting it
%}
function [] = rectBall()
	clc
	
	f = [];
	ax = [];
	ball = [];
	trail = [];
	rects = [];
	circles = [];
	cx = [];
	cy = [];
	paused = false;
	
	v = 2.5; % speed
	dt = 0.005; % delta time

	fprintf('\n\nLeft Click and drag to create rectangles\nShift Click and drag to create circles\nRight Click to delete shapes\n''Space'' to pause and unpause the ball\n(You can add and remove shapes while paused)\n')
	figureSetup(); % creates the figure and other intial graphics objects
	run();
	
	
	function [] = run()
		while ishandle(f) && ~paused % stops when paused or the figure is closed
			% store current position and calculate new position without
			% collions
			x0 = ball.UserData.x;
			y0 = ball.UserData.y;
			
			vx = ball.UserData.v*cos(ball.UserData.t);
			vy = ball.UserData.v*sin(ball.UserData.t);
			dx = vx*dt;
			dy = vy*dt;
			
			x = x0 + dx;
			y = y0 + dy;
			
			ball.UserData.x = x;
			ball.UserData.y = y;
			ball.XData = ball.XData + dx;
			ball.YData = ball.YData + dy;
			
			if x <= 0 || x >= ax.XLim(2) %bounce on right/left wall
				vx = -vx;
			end
			if y >= ax.YLim(2) || y <= 0 % bounce on bot/top wall
				vy = -vy;
			end
			
			% check to see if the ball bounces on any rectangles
			xBounce = false;
			yBounce = false;
			i = 1;
			while ~(xBounce && yBounce) && i <= length(rects) % check each rectangle, but only allow a single bounce in each direction
				if ~isempty(rects(i).UserData) && between(rects(i).UserData.x1,x,rects(i).UserData.x2) && between(rects(i).UserData.y1,y,rects(i).UserData.y2) % checks if the ball is inside this rect
					if ~xBounce && ~between(rects(i).UserData.x1,x0,rects(i).UserData.x2) % checks if the previous x was inside
						vx = -vx;
						xBounce = true;
					elseif ~yBounce && ~between(rects(i).UserData.y1,y0,rects(i).UserData.y2) % checks if the previous y was insde
						vy = -vy;
						yBounce = true;
					end
				end
				i = i + 1;
			end
			
			% check to see if the ball bounces on any circles
			for i = 1:length(circles)
				xc = circles(i).UserData.x;
				yc = circles(i).UserData.y;
				r = circles(i).UserData.r;
				if dist(x,y,xc,yc) <= r && dist(x0,y0,xc,yc) > r % checks if current position is inside the circle and the previous was not
					% equation of the line drawn between previous and
					% current position (path)
					m = (y-y0)/(x-x0);
					b = y - m*x;
					
					% find insections of path and circle
					xe1 = (-(2*m*b-2*m*yc - 2*xc) + sqrt((2*m*b-2*m*yc - 2*xc)^2 - 4*(m^2+1)*(xc^2+b^2-2*yc*b+yc^2-r^2)))/(2*m^2+2);
					xe2 = (-(2*m*b-2*m*yc - 2*xc) - sqrt((2*m*b-2*m*yc - 2*xc)^2 - 4*(m^2+1)*(xc^2+b^2-2*yc*b+yc^2-r^2)))/(2*m^2+2);
					% pick the one inbetween x and x0
					d = abs(x-x0);
					if abs(x-xe1) <=d && abs(x0-xe1) <= d && isreal(xe1)
						xe = xe1;
					elseif abs(x-xe2) <=d && abs(x0-xe2) <= d && isreal(xe2)
						xe = xe2;
					end
					ye = m*xe+b;
					
					% determine new angle for velocity, t3
					t = abs(ball.UserData.t);
					t2 = abs(atan2(ye - yc, xe - xc));
					t3 = -sign(vy)*t + sign(ye-yc)*(2*t2 - pi);
					
					vx = ball.UserData.v*cos(t3);
					vy = ball.UserData.v*sin(t3);
					ball.XData = ball.UserData.px + xe;
					ball.YData = ball.UserData.py + ye;
					ball.UserData.x = xe;
					ball.UserData.y = ye;
				end
			end
			
			
			ball.UserData.t = atan2(vy, vx); % update velocity angle
			
			trail.addpoints(x,y) % update trail
			pause(dt)
		end
	end
	
	% controls keyboard responses
	function [] = keyboard(~,evt)
% 		evt.Key
		switch evt.Key
			case 'space' % pause/unpause
				paused = ~paused;
				if ~paused
					run();
				end
			case 'backspace' % clear all shapes
				delete(rects);
				delete(circles);
				rects = rects(ishandle(rects));
				circles = circles(ishandle(circles));
		end
	end
	
	% handles mouse clicks
	function [] = click(~,~)
		f.UserData.CurSelectionType = f.SelectionType;
		f.WindowButtonDownFcn = {}; % removes click() as a callback to prevent glitches
		switch f.SelectionType
			case 'normal' %left click, add rect
				m = ax.CurrentPoint([1,3]);
				ax.UserData = m;
				rects(end+1) = patch([m(1) m(1) m(1) m(1)],[m(2) m(2) m(2) m(2)],[0 0 0]);
				f.WindowButtonMotionFcn = @mouseMove;
			case 'extend' % shift+left click, add circle
				m = ax.CurrentPoint([1,3]);
				ax.UserData = m;
				
				circles(end+1) = patch(m(1) + cx*0,m(2) + cy*0,[0 0 0]);
				circles(end).UserData.x = m(1);
				circles(end).UserData.y = m(2);
				circles(end).UserData.r = 0;
				f.WindowButtonMotionFcn = @mouseMove;
			case 'alt'
				%delete rect
		end
	end
	
	% shows preview of new rects and circles
	function [] = mouseMove(~,~)
		switch f.UserData.CurSelectionType % f.SelectionType
			case 'normal'
				rects(end).XData([3,4]) = ax.CurrentPoint(1);
				rects(end).YData([2,3]) = ax.CurrentPoint(3);
			case 'extend'
				r = dist(ax.UserData(1),ax.UserData(2),ax.CurrentPoint(1),ax.CurrentPoint(3));
				circles(end).XData = cx*r + ax.UserData(1);
				circles(end).YData = cy*r + ax.UserData(2);
		end
	end
	
	% triggered when releasing a mouse button
	function [] = unclick(~,~)
		switch f.UserData.CurSelectionType % has to compare to stored type
			case 'normal'
				f.WindowButtonMotionFcn = []; %stop the preview function
				m(1,:) = ax.UserData;
				m(2,:) = ax.CurrentPoint([1,3]);

				rects(end).UserData.x1 = min(m(:,1));
				rects(end).UserData.x2 = max(m(:,1));
				rects(end).UserData.y1 = min(m(:,2));
				rects(end).UserData.y2 = max(m(:,2));
			case 'extend'
				f.WindowButtonMotionFcn = [];
				circles(end).UserData.r = dist(ax.UserData(1),ax.UserData(2),ax.CurrentPoint(1),ax.CurrentPoint(3));
			case 'alt'
				m = ax.CurrentPoint([1,3]);
				i = 1;
				while i <= length(rects) % deletes all rects under the mouse
					if ~(m(1) < rects(i).UserData.x1 || m(1) > rects(i).UserData.x2 || m(2) < rects(i).UserData.y1 || m(2) > rects(i).UserData.y2) % checks if the mouse is inside a rect
						delete(rects(i));
					end
					i = i + 1;
				end
				rects = rects(ishandle(rects));
				
				i = 1;
				while i <= length(circles) % deletes all circles under the mouse
					if circles(i).UserData.r >= dist(m(1),m(2),circles(i).UserData.x,circles(i).UserData.y)
						delete(circles(i));
					end
					i = i + 1;
				end
				circles = circles(ishandle(circles));
		end
		f.WindowButtonDownFcn = @click; % re-enable clicking
	end

	
	% This function sets up the window used to play the game. It
	% creates the figure, axes, and other graphics objects.
	function [] = figureSetup()
		f = figure(1);
		clf
		f.MenuBar = 'none';
		f.SizeChangedFcn = @resize;
		f.WindowButtonDownFcn = @click;
		f.WindowButtonUpFcn = @unclick;
		f.WindowKeyPressFcn = @keyboard;
		
		ax = axes(...
			'Parent',f,...
			'Position',[0 0 1 1],...
			'XTick',[],...
			'YTick',[],...
			'XLim',[0 f.Position(3)],...
			'YLim',[0,f.Position(4)],...
			'Box','on');
		axis equal
		ylim manual
		xlim manual
		
		% creates the ball and stores initial physics values in its UserData
		t = linspace(0,2*pi,24);
		x = cos(t)*7;
		y = sin(t)*7;
		ball = patch(f(1).Position(3)/2 + x, f(1).Position(4)/2 + y, [0.5 0.5 0.95],'EdgeColor','none');
		ball.UserData.x = f(1).Position(3)/2;
		ball.UserData.y = f(1).Position(4)/2;
		ball.UserData.v = v/dt;
		ball.UserData.t = pi/4;%2*pi*rand;
		ball.UserData.px = x;
		ball.UserData.py = y;
		
		% creates the ball's trail
		trail = animatedline(ball.UserData.x,ball.UserData.y,'MaximumNumPoints',100);
		uistack(trail,'bottom');
		
		rects = matlab.graphics.primitive.Patch.empty;
		circles = matlab.graphics.primitive.Patch.empty;
		
		% creates the coordinates used for drawing circles later
		t = linspace(0,2*pi,48);
		cx = cos(t);
		cy = sin(t);
		
	end
	
	% handles figure resizing
	function [] = resize(~,~)
		ax.XLim(2) = f.Position(3); % resize axes
		ax.YLim(2) = f.Position(4);
		
		% checks if the ball needs to be moved if the axes is shrunk
		if ball.UserData.x > ax.XLim(2) || ball.UserData.y > ax.YLim(2)
			ball.UserData.x = ax.XLim(2)/2;
			ball.UserData.y = ax.YLim(2)/2;
			ball.XData = ball.UserData.px + ball.UserData.x;
			ball.YData = ball.UserData.py + ball.UserData.y;
		end
	end
end

% 2 short helper functions to make if statements neater
function [itIs] = between(a,b,c)
	itIs = (a <= b && b <= c);
end

function [d] = dist(x1,y1,x2,y2)
	d = sqrt((x1-x2).^2 + (y1-y2).^2);
end