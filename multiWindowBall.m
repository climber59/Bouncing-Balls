%{

%}
function [] = multiWindowBall()
	clc, close all force
	
	f = [];
	ax = [];
	ball = [];
	running = true;
	root = groot;
	needsDeleting = 0;
	
	v = 3;
	dt = 0.01;
	
	fprintf('\n\nMove, resize, overlap, isolate, and delete the figures\n''Enter'' to make a new figure\n''Space'' to pause and unpause the ball\nArrow keys to change the velocity\n')
	figureSetup();
	run();
	
	function [] = run()
		while running
			% standard physics equations to move the ball
			vx = ball.UserData.v*cos(ball.UserData.t);
			vy = ball.UserData.v*sin(ball.UserData.t);
			dx = vx*dt;
			dy = vy*dt;
			
			x = ball.UserData.x + dx;
			y = ball.UserData.y + dy;
			ball.XData = ball.XData + dx;
			ball.YData = ball.YData + dy;
			ball.UserData.x = x;
			ball.UserData.y = y;
			
			
			figOrder = [root.Children.UserData]; % the order of figure windows to determine which is on top
			
			% jump to more forward figure if needed
			i = 1;
			j = false;
			while i < length(figOrder) && ~j
				if ball.UserData.axis == figOrder(i) % already on the top figure at x,y
					j = true;
				elseif ballInRect(f(figOrder(i)))
					[x,y] = jump(ball.UserData.axis,figOrder(i));
					j = true;
				end
				i = i + 1;
			end
			
			% Bounce checks
			cf = ball.UserData.axis; % current figure index
			bir = ballInRect(f); % bool array of whether its in each figure
			
			if sum(bir)==0 % just bounce off the figure it's in now
				if x<=0 || x>=ball.Parent.XLim(2) %bounce on right/left wall
					vx = -vx;
				end
				if y>=ball.Parent.YLim(2) || y<=0 % bounce on bot/top wall
					vy = -vy;
				end
			elseif bir(cf)==0 %leaving cf, but inside another
				jump(ball.UserData.axis,find(bir,1));
			end
			
			
			ball.UserData.t = atan2(vy, vx);
			
			if needsDeleting
				deleteAFig(needsDeleting); % ensures closed figures are deleted at a time when they won't cause errors
			end
			
			pause(dt);
			
			
			
		end
	end
	
	% handles moving the ball to a new figure
	function [x,y] = jump(from, to)
		%convert axis x,y to screen x,y, then to new axis x,y
		x = ball.UserData.x + f(from).Position(1) - f(to).Position(1);
		y = ball.UserData.y + f(from).Position(2) - f(to).Position(2);

		ball.UserData.x = x;
		ball.UserData.y = y;
		ball.XData = ball.UserData.px + x;
		ball.YData = ball.UserData.py + y;


		ball.UserData.axis = to;
		ball.Parent = ax(to);
	end
	
	% Creates the initial graphics objects
	function [] = figureSetup()
		
		for i = 1:max(length(root.Children),2)
			newFigure();
		end
		
		t=linspace(0,2*pi,24);
		x = cos(t)*7;
		y = sin(t)*7;
		ball = patch(ax(2),f(2).Position(3)/2+x,f(2).Position(4)/2+y,[0 0 0]);
		ball.UserData.x = f(2).Position(3)/2;
		ball.UserData.y = f(2).Position(4)/2;
		ball.UserData.v = v/dt;
		ball.UserData.t = 2*pi*rand;
		ball.UserData.px = x;
		ball.UserData.py = y;
		ball.UserData.axis = 2;
	end
	
	% returns whether the ball is within the bounds of fig
	function [o] = ballInRect(fig)
		o = ones(size(fig));
		for i = 1:length(fig)
			x = ball.UserData.x + ball.Parent.Parent.Position(1);
			y = ball.UserData.y + ball.Parent.Parent.Position(2);
			% If the ball is left of the fig
			if x > sum(fig(i).Position([1,3])) || fig(i).Position(1) > x
				o(i) = false;
			end
			% If the ball is above the fig
			if y < fig(i).Position(2) || sum(fig(i).Position([2,4])) < y
				o(i) = false;
			end
		end
	end
	
	% handles resizing figures
	function [] = resize(src,~)
		a = src.Children;
		a.XLim(2) = src.Position(3); % adjust axis size
		a.YLim(2) = src.Position(4);

		% need to check if ball is now outside visible axes
		if src == ball.Parent.Parent && (ball.UserData.x >= a.XLim(2) || ball.UserData.x <= 0 || ball.UserData.y >= a.YLim(2) || ball.UserData.y <= 0)
			ball.UserData.x = a.XLim(2)/2;
			ball.UserData.y = a.YLim(2)/2;
			ball.XData = ball.UserData.px + ball.UserData.x;
			ball.YData = ball.UserData.py + ball.UserData.y;
		end
	end
	
	function [] = keyPress(~,evt)
% 		evt.Key
		switch evt.Key
			case 'return' % new fig
				newFigure();
			case 'space' % (un)pause
				running = ~running;
				if running
					run();
				end
			case 'uparrow' % raise speed
				ball.UserData.v = ball.UserData.v*1.1;
			case 'downarrow' % decrease speed
				ball.UserData.v = ball.UserData.v/1.1;
			case 'leftarrow' % turn
				ball.UserData.t = ball.UserData.t + pi/12;
			case 'rightarrow' % turn the other way
				ball.UserData.t = ball.UserData.t - pi/12;
		end
	end
	
	% handles creating and intializing new figures and axes
	function [] = newFigure()
		n = length(f)+1;
		if n==1
			f = gobjects(1,1);
			ax = gobjects(1,1);
		end
		f(n) = figure;
		clf
		f(n).MenuBar = 'none';
		f(n).UserData = n;
		f(n).SizeChangedFcn = @resize;
		f(n).WindowKeyPressFcn = @keyPress;
		f(n).CloseRequestFcn = @figClose;
		
		ax(n) = axes(...
			'Parent',f(n),...
			'Position',[0 0 1 1],...
			'XTick',[],...
			'YTick',[],...
			'XLim',[0 f(n).Position(3)],...
			'YLim',[0,f(n).Position(4)],...
			'Box','on');
		axis equal
		ylim manual
		xlim manual
	end
	
	% marks figure for deletion when closed by the user. Prevents errors if
	% they were closed in the middle of a function
	function [] = figClose(src,~)
		if ~running
			deleteAFig(src.UserData);
		else
			needsDeleting = src.UserData;
		end
	end
	
	% deletes closed figures without causing errors
	function [] = deleteAFig(n)
		% move the ball if needed
		if ball.UserData.axis == f(n).UserData
			if length(f)==1
				running = false; % stop the main loop if the last figure is closed
			else
				figs = [root.Children.UserData];
				new = figs(find(n~=figs,1)); % pick the top figure
				jump(n,new);
				resize(f(new)); % resize() will put the ball on screen if it isn't already
			end
		end
		
		delete(f(n)) %delete fig
		ax = ax(ishandle(f)); %clean arrays
		f = f(ishandle(f));
		for i = 1:length(f) %get & store new indices
			if ball.UserData.axis == f(i).UserData
				ball.UserData.axis = i;
			end
			f(i).UserData = i;
		end
		needsDeleting = false;
	end
end











