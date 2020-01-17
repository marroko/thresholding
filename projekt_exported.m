classdef projekt_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure  matlab.ui.Figure
        WczytanieobrazuButton        matlab.ui.control.Button
        BinaryzacjametodOtsuButton   matlab.ui.control.Button
        BinaryzacjazprogiemadaptiveButton  matlab.ui.control.Button
        BinaryzacjazprogiemwasnymButton  matlab.ui.control.Button
        PrgwasnyEditFieldLabel       matlab.ui.control.Label
        PrgwasnyEditField            matlab.ui.control.NumericEditField
        Slider                       matlab.ui.control.Slider
        UIAxes                       matlab.ui.control.UIAxes
        UIAxes2                      matlab.ui.control.UIAxes
        MiejscenawczytanyobrazLabel  matlab.ui.control.Label
        MiejscenazbinaryzowanyobrazLabel  matlab.ui.control.Label
        NajpierwwybierzobrazLabel    matlab.ui.control.Label
        ZamianasygnauztemButton      matlab.ui.control.Button
        Sygna1ToLabel                matlab.ui.control.Label
    end


    properties (Access = public)
        OriginalImage           double
        BinarizedImage          double
        ImageChosen             logical
        BinarizedImageGenerated logical
        SignalIsSwapped         logical
    end

    methods (Access = private)
    
        function result = binarizeWithOtsu(~, image)
            tmpImage = image;
            curr_k = -1;
            curr_W_w = 1000;
            N = numel(tmpImage);
            
            for k = 0.01:0.02:1
                
                below = tmpImage(tmpImage<k);
                above = tmpImage(tmpImage>k);
                
                
                N_0 = numel(below);
                N_1 = numel(above);
                
                S_0 = sum(below); 
                S_1 = sum(above);
                
                X_0 = S_0/N_0; % œrednia jasnoœæ piksela w klasie
                X_1 = S_1/N_1;
                
                W_0 = (sum((below - X_0).^2)) / N_0;
                W_1 = (sum((above - X_1).^2)) / N_1;
                W_w = (N_0/N)*W_0 + (N_1/N)*W_1; % suma wa¿ona wariancji wewn¹trzklasowych
                
                if curr_k < 0 || W_w < curr_W_w
                    curr_W_w = W_w;
                    curr_k = k;
                end
            end
            
            tmpImage(tmpImage > curr_k) = 1;
            tmpImage(tmpImage <= curr_k) = 0;

            result = tmpImage;
       	end

        function result = binarizeWithAdaptive(~, image)

            N = 2*floor(size(image)/16)+1; % wartosc domyslna dla matlaba
            [h, w, ~] = size(image);
            result = zeros(h, w);
            N2 = floor(N/2);
            
            for i=1+N2:h-N2
                for j=1+N2 : w-N2
                    image2 = image(i-N2:i+N2 , j-N2:j+N2);
                    threshold = mean(mean(image2));
                    
                    if image(i, j) > threshold
                        result(i,j) = 1;
                    else
                        result(i,j) = 0;
                    end
                end
            end
        end
    end


    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            set(app.UIAxes, 'visible', 'off');
            set(app.UIAxes2, 'visible', 'off');
            set(app.UIAxes, 'xtick', []);
            set(app.UIAxes, 'ytick', []);
            set(app.UIAxes2, 'xtick', []);
            set(app.UIAxes2, 'ytick', []);
            app.NajpierwwybierzobrazLabel.Text = {''};
            app.ImageChosen = false;
            app.BinarizedImageGenerated = false;
            app.SignalIsSwapped = false;
        end

        % Button pushed function: BinaryzacjazprogiemadaptiveButton
        function binarizeWithAdaptiveThreshold(app, event)
            
            if app.ImageChosen == true
                if app.SignalIsSwapped == true
                    app.BinarizedImage = ~binarizeWithAdaptive(app, app.OriginalImage);
                else
                    app.BinarizedImage = binarizeWithAdaptive(app, app.OriginalImage);
                end
                
                app.MiejscenazbinaryzowanyobrazLabel.Text = {''; ''};
                app.BinarizedImageGenerated = true;
                imshow(app.BinarizedImage, 'parent', app.UIAxes2);
            else
                app.NajpierwwybierzobrazLabel.Text = {'Najpierw wybierz obraz'};
            end
        end

        % Button pushed function: BinaryzacjametodOtsuButton
        function binarizeWithOtsuThreshold(app, event)
        
            if app.ImageChosen == true
                if app.SignalIsSwapped == true
                    app.BinarizedImage = ~binarizeWithOtsu(app, app.OriginalImage);
                else
                    app.BinarizedImage = binarizeWithOtsu(app, app.OriginalImage);
                end
                
                app.MiejscenazbinaryzowanyobrazLabel.Text = {''; ''};
                app.BinarizedImageGenerated = true;
                imshow(app.BinarizedImage, 'parent', app.UIAxes2);
            else
                app.NajpierwwybierzobrazLabel.Text = {'Najpierw wybierz obraz'};
            end
        end

        % Button pushed function: BinaryzacjazprogiemwasnymButton
        function binarizeWithOwnThreshold(app, event)
            
            if app.ImageChosen == true
                tmpImage = app.OriginalImage;
                
                if app.SignalIsSwapped == false
                    tmpImage(app.OriginalImage > app.PrgwasnyEditField.Value) = 1;
                    tmpImage(app.OriginalImage <= app.PrgwasnyEditField.Value) = 0;
                else
                    tmpImage(app.OriginalImage <= app.PrgwasnyEditField.Value) = 1;
                    tmpImage(app.OriginalImage > app.PrgwasnyEditField.Value) = 0;
                end
                
                app.BinarizedImage = tmpImage;
                
                app.MiejscenazbinaryzowanyobrazLabel.Text = {''; ''};
                app.BinarizedImageGenerated = true;
                imshow(app.BinarizedImage, 'parent', app.UIAxes2);
            else
                app.NajpierwwybierzobrazLabel.Text = {'Najpierw wybierz obraz'};
            end
        end

        % Button pushed function: WczytanieobrazuButton
        function loadImage(app, event)
            pause on;
            [file, path] = uigetfile('*.jpg; *.png; *.jpeg; *.PNG; *.JPEG; *.jpeg', 'Wybierz obraz do zbinaryzowania');
            
            if ~isequal(file, 0)
                app.ImageChosen = true;
                app.BinarizedImageGenerated = false;
                app.SignalIsSwapped = false;
                app.Sygna1ToLabel.Text = {'0 - Sygna³'; '1 - T³o'};
                app.NajpierwwybierzobrazLabel.Text = {''};
                
                pathToFile = fullfile(path, file);
                app.OriginalImage = rgb2gray(double(imread(pathToFile)) / 255);
                app.MiejscenawczytanyobrazLabel.Text = {''; ''};
                cla(app.UIAxes2);
                pause(0.4);
                app.MiejscenazbinaryzowanyobrazLabel.Text = {'Miejsce na'; 'zbinaryzowany obraz'};
                imshow(app.OriginalImage, 'parent', app.UIAxes);
            end
        end

        % Button pushed function: ZamianasygnauztemButton
        function swapSignalWithBackground(app, event)
            if app.BinarizedImageGenerated == true
                app.Sygna1ToLabel.Text = {strcat('0' + ~app.SignalIsSwapped, ' - Sygna³'); strcat( '0' + app.SignalIsSwapped, ' - T³o')};
                app.SignalIsSwapped = ~app.SignalIsSwapped;
                app.BinarizedImage = ~app.BinarizedImage;
                imshow(app.BinarizedImage, 'parent', app.UIAxes2);
            else
                app.NajpierwwybierzobrazLabel.Text = {'Najpierw zbinaryzuj obraz'};
            end
        end

        % Callback function: Slider, Slider
        function updateNumericField(app, event)
            app.PrgwasnyEditField.Value = app.Slider.Value;
        end

        % Value changed function: PrgwasnyEditField
        function updateSliderValue(app, event)
            app.Slider.Value = app.PrgwasnyEditField.Value;
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure
            app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure = uifigure;
            app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure.Color = [0.9882 0.8745 0.8745];
            app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure.Position = [100 100 1097 705];
            app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure.Name = 'Binaryzacja - Marek Kie³tyka, Micha³ Leszczyñski';
            app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure.Resize = 'off';

            % Create WczytanieobrazuButton
            app.WczytanieobrazuButton = uibutton(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure, 'push');
            app.WczytanieobrazuButton.ButtonPushedFcn = createCallbackFcn(app, @loadImage, true);
            app.WczytanieobrazuButton.BackgroundColor = [1 1 0];
            app.WczytanieobrazuButton.FontSize = 22;
            app.WczytanieobrazuButton.FontWeight = 'bold';
            app.WczytanieobrazuButton.Position = [50 34 232 52];
            app.WczytanieobrazuButton.Text = 'Wczytanie obrazu';

            % Create BinaryzacjametodOtsuButton
            app.BinaryzacjametodOtsuButton = uibutton(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure, 'push');
            app.BinaryzacjametodOtsuButton.ButtonPushedFcn = createCallbackFcn(app, @binarizeWithOtsuThreshold, true);
            app.BinaryzacjametodOtsuButton.BackgroundColor = [0.502 0.502 0.702];
            app.BinaryzacjametodOtsuButton.FontSize = 16;
            app.BinaryzacjametodOtsuButton.FontWeight = 'bold';
            app.BinaryzacjametodOtsuButton.Position = [269.5 102 122 56];
            app.BinaryzacjametodOtsuButton.Text = {'Binaryzacja'; 'metod¹ Otsu'};

            % Create BinaryzacjazprogiemadaptiveButton
            app.BinaryzacjazprogiemadaptiveButton = uibutton(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure, 'push');
            app.BinaryzacjazprogiemadaptiveButton.ButtonPushedFcn = createCallbackFcn(app, @binarizeWithAdaptiveThreshold, true);
            app.BinaryzacjazprogiemadaptiveButton.BackgroundColor = [0.502 0.502 0.7529];
            app.BinaryzacjazprogiemadaptiveButton.FontSize = 16;
            app.BinaryzacjazprogiemadaptiveButton.FontWeight = 'bold';
            app.BinaryzacjazprogiemadaptiveButton.Position = [50 104 160 53];
            app.BinaryzacjazprogiemadaptiveButton.Text = {'Binaryzacja'; 'z progiem adaptive'};

            % Create BinaryzacjazprogiemwasnymButton
            app.BinaryzacjazprogiemwasnymButton = uibutton(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure, 'push');
            app.BinaryzacjazprogiemwasnymButton.ButtonPushedFcn = createCallbackFcn(app, @binarizeWithOwnThreshold, true);
            app.BinaryzacjazprogiemwasnymButton.BackgroundColor = [0.502 0.502 0.7529];
            app.BinaryzacjazprogiemwasnymButton.FontSize = 16;
            app.BinaryzacjazprogiemwasnymButton.FontWeight = 'bold';
            app.BinaryzacjazprogiemwasnymButton.Position = [445 102 163 56];
            app.BinaryzacjazprogiemwasnymButton.Text = {'Binaryzacja'; 'z progiem w³asnym'};

            % Create PrgwasnyEditFieldLabel
            app.PrgwasnyEditFieldLabel = uilabel(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure);
            app.PrgwasnyEditFieldLabel.HorizontalAlignment = 'right';
            app.PrgwasnyEditFieldLabel.VerticalAlignment = 'top';
            app.PrgwasnyEditFieldLabel.FontSize = 18;
            app.PrgwasnyEditFieldLabel.FontWeight = 'bold';
            app.PrgwasnyEditFieldLabel.FontColor = [0 0.451 0.7412];
            app.PrgwasnyEditFieldLabel.Position = [742 119 122 23];
            app.PrgwasnyEditFieldLabel.Text = 'Próg w³asny';

            % Create PrgwasnyEditField
            app.PrgwasnyEditField = uieditfield(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure, 'numeric');
            app.PrgwasnyEditField.Limits = [0 1];
            app.PrgwasnyEditField.ValueDisplayFormat = '%.3f';
            app.PrgwasnyEditField.ValueChangedFcn = createCallbackFcn(app, @updateSliderValue, true);
            app.PrgwasnyEditField.FontSize = 18;
            app.PrgwasnyEditField.FontWeight = 'bold';
            app.PrgwasnyEditField.FontColor = [0 0.451 0.7412];
            app.PrgwasnyEditField.Position = [872 119 59 23];

            % Create Slider
            app.Slider = uislider(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure);
            app.Slider.Limits = [0 1];
            app.Slider.MajorTicks = [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.Slider.ValueChangedFcn = createCallbackFcn(app, @updateNumericField, true);
            app.Slider.ValueChangingFcn = createCallbackFcn(app, @updateNumericField, true);
            app.Slider.FontSize = 16;
            app.Slider.FontWeight = 'bold';
            app.Slider.FontColor = [0 0.451 0.7412];
            app.Slider.Position = [629 106 416 3];

            % Create UIAxes
            app.UIAxes = uiaxes(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure);
            app.UIAxes.FontSize = 8;
            app.UIAxes.GridAlpha = 0.15;
            app.UIAxes.MinorGridAlpha = 0.25;
            app.UIAxes.Color = [0.9882 0.8706 0.8706];
            app.UIAxes.Position = [41 205 493 436];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure);
            app.UIAxes2.FontSize = 8;
            app.UIAxes2.GridAlpha = 0.15;
            app.UIAxes2.MinorGridAlpha = 0.25;
            app.UIAxes2.Color = [0.9882 0.8706 0.8706];
            app.UIAxes2.Position = [551 205 493 436];

            % Create MiejscenawczytanyobrazLabel
            app.MiejscenawczytanyobrazLabel = uilabel(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure);
            app.MiejscenawczytanyobrazLabel.HorizontalAlignment = 'center';
            app.MiejscenawczytanyobrazLabel.FontSize = 48;
            app.MiejscenawczytanyobrazLabel.Position = [133 373 341 118];
            app.MiejscenawczytanyobrazLabel.Text = {'Miejsce na'; 'wczytany obraz'};

            % Create MiejscenazbinaryzowanyobrazLabel
            app.MiejscenazbinaryzowanyobrazLabel = uilabel(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure);
            app.MiejscenazbinaryzowanyobrazLabel.HorizontalAlignment = 'center';
            app.MiejscenazbinaryzowanyobrazLabel.FontSize = 48;
            app.MiejscenazbinaryzowanyobrazLabel.Position = [571 373 465 118];
            app.MiejscenazbinaryzowanyobrazLabel.Text = {'Miejsce na'; 'zbinaryzowany obraz'};

            % Create NajpierwwybierzobrazLabel
            app.NajpierwwybierzobrazLabel = uilabel(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure);
            app.NajpierwwybierzobrazLabel.VerticalAlignment = 'top';
            app.NajpierwwybierzobrazLabel.FontSize = 28;
            app.NajpierwwybierzobrazLabel.FontColor = [1 0 0];
            app.NajpierwwybierzobrazLabel.Position = [133 170 440 36];
            app.NajpierwwybierzobrazLabel.Text = 'Najpierw wybierz obraz';

            % Create ZamianasygnauztemButton
            app.ZamianasygnauztemButton = uibutton(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure, 'push');
            app.ZamianasygnauztemButton.ButtonPushedFcn = createCallbackFcn(app, @swapSignalWithBackground, true);
            app.ZamianasygnauztemButton.BackgroundColor = [0.302 0.749 0.9294];
            app.ZamianasygnauztemButton.FontSize = 22;
            app.ZamianasygnauztemButton.FontWeight = 'bold';
            app.ZamianasygnauztemButton.Position = [343 34 265 52];
            app.ZamianasygnauztemButton.Text = 'Zamiana sygna³u z t³em';

            % Create Sygna1ToLabel
            app.Sygna1ToLabel = uilabel(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure);
            app.Sygna1ToLabel.VerticalAlignment = 'top';
            app.Sygna1ToLabel.FontWeight = 'bold';
            app.Sygna1ToLabel.Position = [551 7 61 28];
            app.Sygna1ToLabel.Text = {'0 - Sygna³'; '1 - T³o'};
        end
    end

    methods (Access = public)

        % Construct app
        function app = projekt_exported

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.BinaryzacjaMarekKietykaMichaLeszczyskiUIFigure)
        end
    end
end