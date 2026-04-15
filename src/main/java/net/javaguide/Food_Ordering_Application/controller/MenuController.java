package net.javaguide.Food_Ordering_Application.controller;

import net.javaguide.Food_Ordering_Application.dto.MenuDto;
import net.javaguide.Food_Ordering_Application.service.MenuService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/restaurants")
public class MenuController {

    private final MenuService menuService;

    public MenuController(MenuService menuService) {
        this.menuService = menuService;
    }

    //CREATE MENU FOR PARTICULAR RESTAURANT
    @PostMapping("/{restaurantId}/menus")
    public ResponseEntity<MenuDto> createMenu(@PathVariable("restaurantId") Long restaurantId, @RequestBody MenuDto menuDto){

        System.out.println("restaurantId:"+restaurantId );
        System.out.println("Menu:"+ menuDto);
        MenuDto savedMenuDto =  menuService.createMenu(restaurantId,menuDto);
        return new ResponseEntity<>(savedMenuDto, HttpStatus.CREATED);

    }

    //GET ANY MENU BY menuId
    @GetMapping("/menus/{menuId}")
    public ResponseEntity<MenuDto> getMenuById(@PathVariable("menuId") Long menuId){

       MenuDto getMenu = menuService.getMenuById(menuId);

       return ResponseEntity.ok(getMenu);
    }

    //GET ALL MENUS
    @GetMapping("/menus")
    public ResponseEntity<List<MenuDto>> getAllMenus(){
       List<MenuDto> menu =  menuService.getAllMenus();
       return ResponseEntity.ok(menu);
    }

    //GET MENUS FOR PARTICULAR RESTAURANT
    @GetMapping("/{restaurantId}/menus")
     public ResponseEntity<List<MenuDto>> getMenus(@PathVariable("restaurantId") Long restaurant_Id){
        List<MenuDto> menu =  menuService.getMenus(restaurant_Id);
        return ResponseEntity.ok(menu);
     }


}
