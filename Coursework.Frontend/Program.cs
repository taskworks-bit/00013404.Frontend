using Coursework.Frontend.Services;
using RestSharp;

var builder = WebApplication.CreateBuilder(args);

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