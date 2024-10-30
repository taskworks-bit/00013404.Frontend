using Coursework.Frontend.Services;
using RestSharp;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Debug() // Set the minimum log level
    .WriteTo.Console() // Log to console
    .WriteTo.File("Logs/myapp-.log", rollingInterval: RollingInterval.Day) // Log to file
    .CreateLogger();

builder.Host.UseSerilog(); // Use Serilog for logging

builder.Services.AddControllersWithViews();

var baseUrl = builder.Configuration["ApiGateway:BaseUrl"];
builder.Services.AddScoped(sp => new RestClient(baseUrl!));
builder.Services.AddScoped<ProductService>(); 

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Product}/{action=Index}/{id?}");

app.Run();